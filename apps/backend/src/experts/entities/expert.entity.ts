import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { Parcel } from '../../parcels/entities/parcel.entity';

@Entity('experts')
export class Expert {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  specialization: string;

  @Column({ type: 'float' })
  consultationFee: number; // Prix par diagnostic
}

@Entity('expert_requests')
export class ExpertRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Parcel)
  parcel: Parcel;

  @ManyToOne(() => Expert)
  expert: Expert;

  @Column({ default: 'pending' })
  status: 'pending' | 'paid' | 'completed' | 'cancelled';

  @Column({ nullable: true })
  paymentReference: string;

  @Column({ type: 'text', nullable: true })
  context: string;

  @Column({ type: 'text', nullable: true })
  expertAdvice: string;

  // Traçabilité de la facturation wallet — utilisée pour rembourser
  // automatiquement en cas d'annulation de la demande.
  @Column({ type: 'uuid', nullable: true })
  userId: string;

  @Column({ type: 'int', nullable: true })
  feeAmount: number;

  @Column({ nullable: true })
  feeReference: string;

  @CreateDateColumn()
  createdAt: Date;
}
