import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Expert, ExpertRequest } from './entities/expert.entity';
import { CreateExpertRequestDto } from './dto/create-expert-request.dto';
import { PaymentService } from './payment.service';
import { User, UserRole, UserStatus } from '../users/entities/user.entity';
import { PushNotificationService } from '../notifications/push-notification.service';

@Injectable()
export class ExpertsService {
  private readonly logger = new Logger(ExpertsService.name);

  constructor(
    @InjectRepository(Expert)
    private expertRepo: Repository<Expert>,
    @InjectRepository(ExpertRequest)
    private requestRepo: Repository<ExpertRequest>,
    @InjectRepository(User)
    private userRepo: Repository<User>,
    private paymentService: PaymentService,
    private pushService: PushNotificationService,
  ) {}

  async findAll() {
    return this.expertRepo.find();
  }

  async createRequest(dto: CreateExpertRequestDto) {
    const expert = dto.expertId
      ? await this.expertRepo.findOneBy({ id: dto.expertId })
      : null;

    if (dto.expertId && !expert) throw new NotFoundException('Expert non trouvé');

    const request = this.requestRepo.create({
      parcel: { id: dto.parcelId },
      ...(expert ? { expert } : {}),
      context: dto.context,
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
    const saved = await this.requestRepo.save(request);

    if (saved.status === 'completed') {
      await this.notifyTechnicianExpertResponded(saved);
    }

    return saved;
  }

  async notifyTechnicianExpertResponded(request: ExpertRequest): Promise<void> {
    try {
      this.logger.log(`[Push Notification] Recherche du technicien pour la demande expert complétée ${request.id}`);
      const parcel = request.parcel;
      let technicianUser: User | null = null;

      if (parcel && parcel.technician) {
        technicianUser = await this.userRepo.findOneBy({ name: parcel.technician });
      }

      if (!technicianUser) {
        technicianUser = await this.userRepo.findOne({
          where: { role: UserRole.TECHNICIAN, status: UserStatus.ACTIVE },
          order: { createdAt: 'ASC' },
        });
      }

      if (technicianUser) {
        const title = `Avis d'expert disponible 👨‍🌾`;
        const body = `L'expert a répondu à votre demande pour la parcelle ${parcel?.name || request.id}. Consultez l'avis dès maintenant.`;
        await this.pushService.sendPushToTechnician(technicianUser, title, body, {
          expertRequestId: request.id,
          parcelId: parcel?.id,
          type: 'EXPERT_ADVICE_RESPONDED',
        });
      } else {
        this.logger.warn(`Aucun technicien trouvé pour notifier la réponse expert ${request.id}`);
      }
    } catch (error) {
      this.logger.error(`Erreur lors de la notification push au technicien pour la demande expert ${request.id}: ${error.message}`);
    }
  }
}
