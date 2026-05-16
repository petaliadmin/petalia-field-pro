import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WalletTransaction, TransactionType, WalletOperationType } from './entities/wallet-transaction.entity';

@Injectable()
export class WalletService {
  constructor(
    @InjectRepository(WalletTransaction)
    private transactionRepository: Repository<WalletTransaction>,
  ) {}

  async getBalance(userId: string): Promise<number> {
    const result = await this.transactionRepository
      .createQueryBuilder('t')
      .select('SUM(CASE WHEN t.type = :credit THEN t.amount ELSE -t.amount END)', 'sum')
      .where('t.userId = :userId', { userId, credit: TransactionType.CREDIT })
      .getRawOne();
    
    return Number(result?.sum || 0);
  }

  async addCredits(userId: string, amount: number, description: string, reference?: string) {
    if (amount <= 0) {
      throw new BadRequestException('Le montant doit être supérieur à zéro');
    }

    const transaction = this.transactionRepository.create({
      userId,
      amount,
      description,
      reference,
      type: TransactionType.CREDIT,
      operationType: WalletOperationType.TOPUP,
    });
    return this.transactionRepository.save(transaction);
  }

  async useCredits(userId: string, amount: number, description: string) {
    if (amount <= 0) {
      throw new BadRequestException('Le montant doit être supérieur à zéro');
    }

    return this.transactionRepository.manager.transaction(async (manager) => {
      const balance = await this.getBalanceWithManager(manager, userId);
      if (balance < amount) {
        throw new BadRequestException('Solde de crédits insuffisant');
      }

      const transaction = manager.create(WalletTransaction, {
        userId,
        amount,
        description,
        type: TransactionType.DEBIT,
        operationType: WalletOperationType.TOPUP,
      });
      return manager.save(transaction);
    });
  }

  async performAdminTransaction(
    adminId: string,
    userId: string,
    operationType: WalletOperationType,
    amount: number,
    description: string,
  ) {
    if (amount === 0) {
      throw new BadRequestException('Le montant ne peut pas être zéro');
    }

    return this.transactionRepository.manager.transaction(async (manager) => {
      let type = TransactionType.CREDIT;
      let absAmount = amount;

      if (operationType === WalletOperationType.REGULATION) {
        // La régulation est un retrait / débit par l'admin
        type = TransactionType.DEBIT;
        absAmount = Math.abs(amount);

        const balance = await this.getBalanceWithManager(manager, userId);
        if (balance < absAmount) {
          throw new BadRequestException(`Solde insuffisant pour cette régulation (Solde actuel: ${balance})`);
        }
      } else if (operationType === WalletOperationType.AJUSTEMENT) {
        if (amount < 0) {
          type = TransactionType.DEBIT;
          absAmount = Math.abs(amount);

          const balance = await this.getBalanceWithManager(manager, userId);
          if (balance < absAmount) {
            throw new BadRequestException(`Solde insuffisant pour cet ajustement négatif (Solde actuel: ${balance})`);
          }
        } else {
          type = TransactionType.CREDIT;
          absAmount = amount;
        }
      } else {
        // RECHARGE ou TOPUP
        type = TransactionType.CREDIT;
        absAmount = Math.abs(amount);
      }

      const transaction = manager.create(WalletTransaction, {
        userId,
        amount: absAmount,
        description,
        type,
        operationType,
        adminId,
        reference: `ADMIN_${operationType}_${Date.now()}`,
      });

      return manager.save(transaction);
    });
  }

  private async getBalanceWithManager(manager: any, userId: string): Promise<number> {
    const result = await manager
      .createQueryBuilder(WalletTransaction, 't')
      .select('SUM(CASE WHEN t.type = :credit THEN t.amount ELSE -t.amount END)', 'sum')
      .where('t.userId = :userId', { userId, credit: TransactionType.CREDIT })
      .setLock('pessimistic_write') // Protection contre les accès concurrents
      .getRawOne();
    
    return Number(result?.sum || 0);
  }
}
