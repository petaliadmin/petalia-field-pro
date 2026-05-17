import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('sync_outbox')
export class SyncOutbox {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  entityId: string;

  @Column()
  entityType: string; // 'parcel', 'observation', 'expert_request', 'wallet'

  @Column()
  operation: string; // 'create', 'update', 'delete'

  @Column({ type: 'jsonb', nullable: true })
  payload: any;

  @Column({ default: false })
  processed: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
