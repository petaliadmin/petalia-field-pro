import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum DiagnosticStatus {
  PENDING = 'pending',
  ANALYZED = 'analyzed',
  VALIDATED = 'validated',
  REJECTED = 'rejected',
}

@Entity('diagnostic_requests')
export class DiagnosticRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  parcelId: string;

  @Column()
  ownerName: string;

  @Column()
  ownerPhone: string;

  @Column()
  photoUrl: string;

  @Column({
    type: 'enum',
    enum: DiagnosticStatus,
    default: DiagnosticStatus.PENDING,
  })
  status: DiagnosticStatus;

  @Column({ type: 'jsonb', nullable: true })
  aiResult: {
    label: string;
    confidence: number;
    suggestedSymptoms: string[];
    recommendations: string;
  };

  @Column({ nullable: true })
  adminComment: string;

  @Column({ nullable: true })
  validatedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
