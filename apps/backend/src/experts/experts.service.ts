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
import { WalletService } from '../wallet/wallet.service';
import { EXPERT_REQUEST_DEFAULT_FEE_XOF } from '../common/constants/billing';

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
    private walletService: WalletService,
  ) {}

  async findAll() {
    return this.expertRepo.find();
  }

  async createRequest(dto: CreateExpertRequestDto, userId: string) {
    if (!userId) {
      throw new BadRequestException(
        "Identifiant utilisateur requis pour facturer la demande d'avis expert",
      );
    }

    const expert = dto.expertId
      ? await this.expertRepo.findOneBy({ id: dto.expertId })
      : null;

    if (dto.expertId && !expert) throw new NotFoundException('Expert non trouvé');

    // Le tarif réel = consultationFee de l'expert si choisi, sinon repli constant.
    const feeAmount = expert?.consultationFee
      ? Math.round(Number(expert.consultationFee))
      : EXPERT_REQUEST_DEFAULT_FEE_XOF;

    // 1. Créer la demande en pending pour disposer d'un id stable.
    const request = this.requestRepo.create({
      parcel: { id: dto.parcelId },
      ...(expert ? { expert } : {}),
      context: dto.context,
      status: 'pending',
      userId,
      feeAmount,
    });
    const saved = await this.requestRepo.save(request);

    // 2. Débit réel du wallet du technicien. Si solde insuffisant
    //    on supprime la demande pour rester cohérent.
    const reference = `EXPERT_REQ_${saved.id}`;
    try {
      await this.walletService.useCredits(
        userId,
        feeAmount,
        `Demande avis expert${expert ? ` (${expert.name})` : ''} #${saved.id}`,
        reference,
      );
    } catch (err) {
      await this.requestRepo.delete(saved.id);
      throw err;
    }

    // 3. Le paiement étant effectué via wallet, la demande passe directement
    //    en `paid` — plus besoin d'un /pay externe.
    saved.status = 'paid';
    saved.paymentReference = reference;
    saved.feeReference = reference;
    return this.requestRepo.save(saved);
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

    const wasAlreadyClosed =
      request.status === 'cancelled' || request.status === 'completed';

    request.expertAdvice = expertAdvice;
    request.status = status;
    const saved = await this.requestRepo.save(request);

    // Remboursement automatique sur annulation.
    if (
      saved.status === 'cancelled' &&
      !wasAlreadyClosed &&
      saved.userId &&
      saved.feeAmount &&
      saved.feeAmount > 0
    ) {
      try {
        await this.walletService.addCredits(
          saved.userId,
          saved.feeAmount,
          `Remboursement demande expert annulée #${saved.id}`,
          `REFUND_${saved.feeReference || saved.id}`,
        );
      } catch (err: any) {
        this.logger.error(
          `Échec du remboursement wallet pour la demande expert ${saved.id}: ${err?.message ?? err}`,
        );
      }
    }

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
