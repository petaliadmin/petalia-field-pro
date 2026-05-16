import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

export enum TransactionType {
  CREDIT = 'CREDIT',
  DEBIT = 'DEBIT',
}

export enum WalletOperationType {
  TOPUP = 'TOPUP', // Mobile money ou recharge auto
  RECHARGE = 'RECHARGE', // Crédit manuel par admin
  AJUSTEMENT = 'AJUSTEMENT', // Correction de solde par admin
  REGULATION = 'REGULATION', // Débit ou gel par admin
}

@Entity('wallet_transactions')
export class WalletTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column({ type: 'enum', enum: TransactionType })
  type: TransactionType;

  @Column({
    type: 'enum',
    enum: WalletOperationType,
    default: WalletOperationType.TOPUP,
  })
  operationType: WalletOperationType;

  @Column('int')
  amount: number;

  @Column()
  description: string;

  @Column({ nullable: true })
  reference: string; // ID de transaction externe (Wave, OM)

  @Column({ nullable: true })
  adminId: string; // ID de l'administrateur auteur de l'acte

  @CreateDateColumn()
  createdAt: Date;
}
