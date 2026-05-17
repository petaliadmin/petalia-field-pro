import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DeepPartial } from 'typeorm';
import { Parcel } from './entities/parcel.entity';
import { SyncOutbox } from './entities/sync-outbox.entity';
import { AgroService } from './agro.service';

@Injectable()
export class ParcelsService {
  constructor(
    @InjectRepository(Parcel)
    private parcelsRepository: Repository<Parcel>,
    @InjectRepository(SyncOutbox)
    private outboxRepository: Repository<SyncOutbox>,
    private agroService: AgroService,
  ) {}

  async findAll(
    page: number = 1,
    limit: number = 10,
  ): Promise<{ data: Parcel[]; total: number }> {
    const [data, total] = await this.parcelsRepository.findAndCount({
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });
    return { data, total };
  }

  async findSyncDeltas(lastSync: string): Promise<{ parcels: Parcel[]; outbox: SyncOutbox[] }> {
    const date = new Date(lastSync);
    const parcels = await this.parcelsRepository
      .createQueryBuilder('p')
      .where('p.updatedAt > :date', { date })
      .getMany();

    const outbox = await this.outboxRepository
      .createQueryBuilder('o')
      .where('o.createdAt > :date', { date })
      .getMany();

    return { parcels, outbox };
  }

  async findOne(id: string): Promise<Parcel> {
    const parcel = await this.parcelsRepository.findOne({ where: { id } });
    if (!parcel) throw new NotFoundException('Parcel not found');
    return parcel;
  }

  async create(parcelData: Partial<Parcel>): Promise<Parcel> {
    const healthScore = this.agroService.calculateHealthScore(new Date());
    const parcel = this.parcelsRepository.create({
      ...parcelData,
      healthScore,
    } as DeepPartial<Parcel>);
    const saved = await this.parcelsRepository.save(parcel);
    await this.outboxRepository.save(
      this.outboxRepository.create({
        entityId: saved.id,
        entityType: 'parcel',
        operation: 'create',
        payload: saved,
      }),
    );
    return saved;
  }

  async upsertSync(clientParcel: any): Promise<Parcel> {
    const existing = await this.parcelsRepository.findOne({ where: { id: clientParcel.id } });
    if (!existing) {
      const healthScore = clientParcel.healthScore ?? this.agroService.calculateHealthScore(new Date());
      const created = this.parcelsRepository.create({ ...clientParcel, healthScore } as DeepPartial<Parcel>);
      const saved = await this.parcelsRepository.save(created);
      await this.outboxRepository.save(
        this.outboxRepository.create({
          entityId: saved.id,
          entityType: 'parcel',
          operation: 'create',
          payload: saved,
        }),
      );
      return saved;
    }

    // Per-Field Merging (Conflict Resolution)
    const clientDate = new Date(clientParcel.lastVisit || clientParcel.updatedAt || new Date());
    const serverDate = existing.updatedAt;

    let merged: any = {};
    if (clientDate > serverDate) {
      merged = { ...existing, ...clientParcel };
    } else {
      merged = {
        ...clientParcel,
        owner: existing.owner,
        phone: existing.phone,
        village: existing.village,
        technician: existing.technician,
        crop: existing.crop,
      };
    }

    await this.parcelsRepository.update(existing.id, merged);
    const updated = await this.findOne(existing.id);

    await this.outboxRepository.save(
      this.outboxRepository.create({
        entityId: updated.id,
        entityType: 'parcel',
        operation: 'update',
        payload: updated,
      }),
    );

    return updated;
  }

  async update(id: string, updateData: Partial<Parcel>): Promise<Parcel> {
    const validKeys = [
      'name',
      'owner',
      'village',
      'phone',
      'technician',
      'crop',
      'healthScore',
      'boundary',
      'estimatedYield',
      'lastVisit',
    ];
    const cleanData: any = {};
    for (const key of validKeys) {
      if (key in updateData && (updateData as any)[key] !== undefined) {
        cleanData[key] = (updateData as any)[key];
      }
    }
    if (Object.keys(cleanData).length > 0) {
      await this.parcelsRepository.update(id, cleanData);
    }
    const updated = await this.findOne(id);
    await this.outboxRepository.save(
      this.outboxRepository.create({
        entityId: updated.id,
        entityType: 'parcel',
        operation: 'update',
        payload: updated,
      }),
    );
    return updated;
  }

  async remove(id: string): Promise<void> {
    await this.parcelsRepository.delete(id);
    await this.outboxRepository.save(
      this.outboxRepository.create({
        entityId: id,
        entityType: 'parcel',
        operation: 'delete',
        payload: { id },
      }),
    );
  }
}
