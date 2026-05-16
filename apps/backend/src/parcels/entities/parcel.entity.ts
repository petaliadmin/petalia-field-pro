import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import * as GeoJSON from 'geojson';
import { EncryptionUtil } from '../../common/utils/encryption.util';

@Entity('parcels')
export class Parcel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({
    transformer: {
      to: (value: string) => (value ? EncryptionUtil.encrypt(value) : value),
      from: (value: string) => (value ? EncryptionUtil.decrypt(value) : value),
    },
  })
  owner: string;

  @Column({ nullable: true })
  village: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  technician: string;

  @Column()
  crop: string;

  @Column({ type: 'float', default: 0 })
  healthScore: number;

  @Column({
    type: 'geometry',
    spatialFeatureType: 'Polygon',
    srid: 4326,
  })
  boundary: GeoJSON.Polygon;

  @Column({ type: 'float', nullable: true })
  estimatedYield: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  lastVisit: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
