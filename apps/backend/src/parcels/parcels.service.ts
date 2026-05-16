import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Parcel } from './entities/parcel.entity';
import { AgroService } from './agro.service';

@Injectable()
export class ParcelsService {
  constructor(
    @InjectRepository(Parcel)
    private parcelsRepository: Repository<Parcel>,
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

  async findOne(id: string): Promise<Parcel> {
    const parcel = await this.parcelsRepository.findOne({ where: { id } });
    if (!parcel) throw new NotFoundException('Parcel not found');
    return parcel;
  }

  create(parcelData: Partial<Parcel>): Promise<Parcel> {
    const healthScore = this.agroService.calculateHealthScore(new Date());
    const parcel = this.parcelsRepository.create({
      ...parcelData,
      healthScore,
    });
    return this.parcelsRepository.save(parcel);
  }

  async remove(id: string): Promise<void> {
    await this.parcelsRepository.delete(id);
  }
}
