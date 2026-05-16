import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('ledger_entries')
export class LedgerEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column()
  type: 'DEBIT' | 'CREDIT';

  @Column()
  currency: string; // Ex: XOF (Franc CFA)

  @Column()
  description: string;

  @Column({ nullable: true })
  reference: string; // ID de transaction externe (PayDunya, Wave)

  @CreateDateColumn()
  createdAt: Date;
}
