import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WalletTransaction, TransactionType, WalletOperationType } from './entities/wallet-transaction.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class WalletService {
  constructor(
    @InjectRepository(WalletTransaction)
    private transactionRepository: Repository<WalletTransaction>,
    private usersService: UsersService,
  ) {}

  async getTransactions(userId: string): Promise<WalletTransaction[]> {
    return this.transactionRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async getBalance(userId: string): Promise<number> {
    const result = await this.transactionRepository
      .createQueryBuilder('t')
      .select(`SUM(CASE WHEN t.type = '${TransactionType.CREDIT}' THEN t.amount ELSE -t.amount END)`, 'sum')
      .where('t.userId = :userId', { userId })
      .getRawOne();

    return Number(result?.sum || 0);
  }

  async transferCredits(
    senderId: string,
    recipientPhone: string,
    amount: number,
    description?: string,
  ) {
    if (amount <= 0) {
      throw new BadRequestException('Le montant doit être supérieur à zéro');
    }

    // Normaliser le numéro
    const phone = recipientPhone.startsWith('+221') ? recipientPhone : '+221' + recipientPhone.replace(/^7/, '7');

    const recipient = await this.usersService.findByPhone(phone);
    if (!recipient) {
      throw new BadRequestException('Producteur introuvable avec ce numéro');
    }

    if (recipient.id === senderId) {
      throw new BadRequestException('Vous ne pouvez pas transférer des crédits à vous-même');
    }

    const sender = await this.usersService.findOne(senderId);

    return this.transactionRepository.manager.transaction(async (manager) => {
      const balance = await this.getBalanceWithManager(manager, senderId);
      if (balance < amount) {
        throw new BadRequestException('Solde de crédits insuffisant');
      }

      const desc = description?.trim() || `Transfert à ${recipient.name || phone}`;

      // 1. Débit de l'émetteur
      const debitTx = manager.create(WalletTransaction, {
        userId: senderId,
        amount,
        description: desc,
        type: TransactionType.DEBIT,
        operationType: WalletOperationType.TRANSFER,
        reference: `TRANSFER_OUT_${Date.now()}`,
      });
      await manager.save(debitTx);

      // 2. Crédit du destinataire
      const creditTx = manager.create(WalletTransaction, {
        userId: recipient.id,
        amount,
        description: `Crédits reçus de ${sender.name || sender.phone}`,
        type: TransactionType.CREDIT,
        operationType: WalletOperationType.TRANSFER,
        reference: `TRANSFER_IN_${Date.now()}`,
      });
      await manager.save(creditTx);

      return { message: 'Transfert effectué avec succès', transaction: debitTx };
    });
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

  async useCredits(userId: string, amount: number, description: string, reference?: string) {
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
        reference: reference || `USE_${Date.now()}`,
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
      .select(`SUM(CASE WHEN t.type = '${TransactionType.CREDIT}' THEN t.amount ELSE -t.amount END)`, 'sum')
      .where('t.userId = :userId', { userId })
      .setLock('pessimistic_write')
      .getRawOne();

    return Number(result?.sum || 0);
  }
}
