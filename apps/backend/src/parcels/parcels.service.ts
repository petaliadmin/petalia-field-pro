import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DeepPartial } from 'typeorm';
import { Parcel } from './entities/parcel.entity';
import { SyncOutbox } from './entities/sync-outbox.entity';
import { AgroService } from './agro.service';
import { GeospatialService } from '../geospatial/geospatial.service';

type OutboxOperation = 'create' | 'update' | 'delete';

@Injectable()
export class ParcelsService {
  private readonly logger = new Logger(ParcelsService.name);

  constructor(
    @InjectRepository(Parcel)
    private parcelsRepository: Repository<Parcel>,
    @InjectRepository(SyncOutbox)
    private outboxRepository: Repository<SyncOutbox>,
    private agroService: AgroService,
    private geospatialService: GeospatialService,
  ) {}

  /**
   * Écriture best-effort dans l'outbox de synchronisation.
   * Un échec ici (table absente, panne transitoire) ne doit jamais
   * faire échouer la mutation métier — la sync se rattrapera via
   * le delta sur `parcels.updatedAt` côté client.
   */
  private async recordOutbox(
    entityId: string,
    operation: OutboxOperation,
    payload: any,
  ): Promise<void> {
    try {
      await this.outboxRepository.save(
        this.outboxRepository.create({
          entityId,
          entityType: 'parcel',
          operation,
          payload,
        }),
      );
    } catch (err: any) {
      this.logger.warn(
        `Outbox write skipped for parcel ${entityId} (${operation}): ${err?.message ?? err}`,
      );
    }
  }

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

  async findSyncDeltas(
    lastSync: string,
  ): Promise<{ parcels: Parcel[]; outbox: SyncOutbox[] }> {
    const date = new Date(lastSync);
    const parcels = await this.parcelsRepository
      .createQueryBuilder('p')
      .where('p.updatedAt > :date', { date })
      .getMany();

    // L'outbox est optionnelle : si elle est indisponible (migration non
    // appliquée, panne transitoire), on renvoie quand même les parcelles.
    let outbox: SyncOutbox[] = [];
    try {
      outbox = await this.outboxRepository
        .createQueryBuilder('o')
        .where('o.createdAt > :date', { date })
        .orderBy('o.createdAt', 'ASC')
        .getMany();
    } catch (err: any) {
      this.logger.warn(
        `Outbox read skipped for sync delta: ${err?.message ?? err}`,
      );
    }

    return { parcels, outbox };
  }

  async findOne(id: string): Promise<Parcel> {
    const parcel = await this.parcelsRepository.findOne({ where: { id } });
    if (!parcel) throw new NotFoundException('Parcel not found');
    return parcel;
  }

  /**
   * Proxy call to the external geospatial engine for a given parcel.
   * Returns the engine JSON payload (metrics, tile URLs, etc.).
   */
  async analyzeParcel(id: string, requestedMetrics: string[] = []): Promise<any> {
    const parcel = await this.findOne(id);
    if (!parcel.boundary) {
      throw new NotFoundException('Parcel geometry missing');
    }
    return this.geospatialService.analyzeParcel(parcel.id, parcel.boundary, requestedMetrics);
  }

  async getLatestAnalysis(id: string): Promise<any> {
    const parcel = await this.findOne(id);
    return this.geospatialService.getFieldLatest(parcel.id);
  }

  async getAlerts(id: string): Promise<any> {
    const parcel = await this.findOne(id);
    return this.geospatialService.getFieldAlerts(parcel.id);
  }

  async getTiles(id: string): Promise<any> {
    const parcel = await this.findOne(id);
    return this.geospatialService.getFieldTiles(parcel.id);
  }

  async getTimeseries(id: string): Promise<any> {
    const parcel = await this.findOne(id);
    return this.geospatialService.getFieldTimeseries(parcel.id);
  }


  async create(parcelData: Partial<Parcel>): Promise<Parcel> {
    const healthScore = this.agroService.calculateHealthScore(new Date());
    const parcel = this.parcelsRepository.create({
      ...parcelData,
      healthScore,
    } as DeepPartial<Parcel>);
    const saved = await this.parcelsRepository.save(parcel);
    await this.recordOutbox(saved.id, 'create', saved);
    return saved;
  }

  async upsertSync(clientParcel: any): Promise<Parcel> {
    if (!clientParcel || !clientParcel.id) {
      throw new NotFoundException('Parcel id is required for sync upsert');
    }

    const existing = await this.parcelsRepository.findOne({
      where: { id: clientParcel.id },
    });
    if (!existing) {
      const healthScore =
        clientParcel.healthScore ??
        this.agroService.calculateHealthScore(new Date());
      const created = this.parcelsRepository.create({
        ...clientParcel,
        healthScore,
      } as DeepPartial<Parcel>);
      const saved = await this.parcelsRepository.save(created);
      await this.recordOutbox(saved.id, 'create', saved);
      return saved;
    }

    // Résolution de conflit "per-field" : la version la plus récente gagne
    // sur les champs métier libres, mais l'identité (owner/phone/village/
    // technician/crop) reste pilotée serveur si le client est en retard.
    const clientDate = new Date(
      clientParcel.lastVisit || clientParcel.updatedAt || new Date(),
    );
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

    // On ne propage jamais id/createdAt depuis le client.
    delete merged.id;
    delete merged.createdAt;

    await this.parcelsRepository.update(existing.id, merged);
    const updated = await this.findOne(existing.id);
    await this.recordOutbox(updated.id, 'update', updated);

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
    await this.recordOutbox(updated.id, 'update', updated);
    return updated;
  }

  async remove(id: string): Promise<void> {
    await this.parcelsRepository.delete(id);
    await this.recordOutbox(id, 'delete', { id });
  }
}
