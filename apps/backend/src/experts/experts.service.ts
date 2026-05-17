import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Expert, ExpertRequest } from './entities/expert.entity';
import { CreateExpertRequestDto } from './dto/create-expert-request.dto';
import { PaymentService } from './payment.service';

@Injectable()
export class ExpertsService {
  constructor(
    @InjectRepository(Expert)
    private expertRepo: Repository<Expert>,
    @InjectRepository(ExpertRequest)
    private requestRepo: Repository<ExpertRequest>,
    private paymentService: PaymentService,
  ) {}

  async findAll() {
    return this.expertRepo.find();
  }

  async createRequest(dto: CreateExpertRequestDto) {
    const expert = await this.expertRepo.findOneBy({ id: dto.expertId });
    if (!expert) throw new NotFoundException('Expert non trouvé');

    const request = this.requestRepo.create({
      expert,
      parcel: { id: dto.parcelId },
      status: 'pending',
    });
    return this.requestRepo.save(request);
  }

  async confirmPayment(id: string, reference: string) {
    const isPaymentValid =
      await this.paymentService.validateTransaction(reference);
    if (!isPaymentValid)
      throw new BadRequestException('Référence de paiement invalide');

    const request = await this.requestRepo.findOneBy({ id });
    if (!request) throw new NotFoundException('Demande non trouvée');

    request.status = 'paid';
    request.paymentReference = reference;
    return this.requestRepo.save(request);
  }

  async findByParcel(parcelId: string) {
    return this.requestRepo.find({
      where: { parcel: { id: parcelId } },
      relations: ['expert', 'parcel'],
      order: { createdAt: 'DESC' },
    });
  }

  async findAllRequests() {
    return this.requestRepo.find({
      relations: ['expert', 'parcel'],
      order: { createdAt: 'DESC' },
    });
  }

  async updateRequestStatus(id: string, expertAdvice: string, status: 'completed' | 'cancelled') {
    const request = await this.requestRepo.findOne({
      where: { id },
      relations: ['parcel', 'expert'],
    });
    if (!request) throw new NotFoundException('Demande non trouvée');

    request.expertAdvice = expertAdvice;
    request.status = status;
    return this.requestRepo.save(request);
  }
}
