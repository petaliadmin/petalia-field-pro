import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DiagnosticRequest, DiagnosticStatus } from './entities/diagnostic-request.entity';
import { CreateDiagnosticDto, ValidateDiagnosticDto } from './dto/diagnostic.dto';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { Parcel } from '../parcels/entities/parcel.entity';
import { User, UserRole, UserStatus } from '../users/entities/user.entity';
import { PushNotificationService } from '../notifications/push-notification.service';
import { ImageAnalysisService, ImageBiometrics } from './image-analysis.service';

@Injectable()
export class DiagnosticsService {
  private readonly logger = new Logger(DiagnosticsService.name);

  constructor(
    @InjectRepository(DiagnosticRequest)
    private readonly repository: Repository<DiagnosticRequest>,
    @InjectRepository(Parcel)
    private readonly parcelRepo: Repository<Parcel>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly pushService: PushNotificationService,
    private readonly configService: ConfigService,
    private readonly imageAnalysisService: ImageAnalysisService,
  ) {}

  async create(createDto: CreateDiagnosticDto, photoUrl: string | null): Promise<DiagnosticRequest> {
    const request = this.repository.create({
      ...createDto,
      photoUrl,
      status: DiagnosticStatus.PENDING,
    });

    const saved = await this.repository.save(request);
    
    // Déclencher l'analyse Claude en arrière-plan
    this.analyzeWithClaude(saved.id);

    return saved;
  }

  async getBiometrics(id: string): Promise<ImageBiometrics> {
    const request = await this.repository.findOneBy({ id });
    if (!request) throw new NotFoundException('Diagnostic introuvable');
    return this.imageAnalysisService.analyzeImage(request.photoUrl, request.id);
  }

  async analyzeWithClaude(id: string): Promise<void> {
    const request = await this.repository.findOneBy({ id });
    if (!request) return;

    try {
      this.logger.log(`Lancement de l'analyse Claude pour le diagnostic ${id}`);
      
      const apiKey = this.configService.get<string>('ANTHROPIC_API_KEY');
      if (!apiKey) {
        this.logger.warn('ANTHROPIC_API_KEY non configurée. Simulation active.');
        await this._simulateClaude(request);
        return;
      }

      const biometrics = await this.imageAnalysisService.analyzeImage(request.photoUrl, request.id);

      const response = await axios.post(
        'https://api.anthropic.com/v1/messages',
        {
          model: 'claude-3-5-sonnet-20241022',
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: `Tu es un expert agronome senior spécialisé dans les cultures d'Afrique de l'Ouest (Sénégal). 
              Analyse cette demande pour la parcelle ${request.parcelId} appartenant à ${request.ownerName}.
              Voici les métriques biométriques foliaires exactes extraites de l'image par notre moteur d'analyse :
              - Score de netteté (Blur Score) : ${biometrics.blurScore} (0=flou, 1=net)
              - Taux de chlorose (jaunissement) : ${biometrics.chlorosisRatio * 100}% de la surface
              - Taux de nécrose (brunissement/taches) : ${biometrics.necrosisRatio * 100}% de la surface
              
              Prends en compte ces données biométriques pour affiner ton diagnostic.
              Renvoie UNIQUEMENT un objet JSON valide avec cette structure exacte :
              {
                "label": "Nom de la maladie ou ravageur",
                "confidence": 0.95,
                "suggestedSymptoms": ["symptome1", "symptome2"],
                "recommendations": "Recommandations agronomiques détaillées et adaptées au contexte local"
              }`,
            },
          ],
        },
        {
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        },
      );

      const result = JSON.parse(response.data.content[0].text);
      
      request.aiResult = result;
      request.status = DiagnosticStatus.ANALYZED;
      await this.repository.save(request);

    } catch (error) {
      this.logger.error(`Erreur lors de l'analyse Claude: ${error.message}`);
    }
  }

  async validate(id: string, validateDto: ValidateDiagnosticDto): Promise<DiagnosticRequest> {
    const request = await this.repository.findOneBy({ id });
    if (!request) throw new NotFoundException('Diagnostic introuvable');

    request.status = validateDto.approve === false ? DiagnosticStatus.REJECTED : DiagnosticStatus.VALIDATED;
    request.adminComment = validateDto.adminComment ?? validateDto.comment ?? '';
    request.validatedAt = new Date();

    const saved = await this.repository.save(request);

    // Envoyer les notifications multicanales
    await this.notifyFarmer(saved);

    // Envoi de la notification push au technicien si validé
    if (saved.status === DiagnosticStatus.VALIDATED) {
      await this.notifyTechnicianDiagnosticValidated(saved);
    }

    return saved;
  }

  async notifyTechnicianDiagnosticValidated(request: DiagnosticRequest): Promise<void> {
    try {
      this.logger.log(`[Push Notification] Recherche du technicien pour le diagnostic validé ${request.id} (ParcelID: ${request.parcelId})`);
      const parcel = await this.parcelRepo.findOneBy({ id: request.parcelId });
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
        const title = `Diagnostic IA validé 🎉`;
        const body = `Le diagnostic IA pour la parcelle ${parcel?.name || request.parcelId} a été examiné et validé par un expert.`;
        await this.pushService.sendPushToTechnician(technicianUser, title, body, {
          diagnosticId: request.id,
          parcelId: request.parcelId,
          type: 'DIAGNOSTIC_VALIDATED',
        });
      } else {
        this.logger.warn(`Aucun technicien trouvé pour notifier la validation du diagnostic ${request.id}`);
      }
    } catch (error) {
      this.logger.error(`Erreur lors de la notification push au technicien pour le diagnostic ${request.id}: ${error.message}`);
    }
  }

  async notifyFarmer(request: DiagnosticRequest): Promise<void> {
    this.logger.log(`Envoi des notifications pour le producteur ${request.ownerName}`);

    const resultLink = `https://petalia.ag/r/${request.id}`;
    const message = `Bonjour ${request.ownerName}, votre diagnostic Petalia est prêt. Résultat : ${request.aiResult?.label}. Voir ici : ${resultLink}`;

    // 1. WhatsApp Simulation/API
    await this._sendWhatsApp(request.ownerPhone, message);

    // 2. SMS Simulation/API
    await this._sendSms(request.ownerPhone, message);
  }

  private async _sendWhatsApp(phone: string, message: string) {
    this.logger.log(`[WhatsApp] Envoi à ${phone}: ${message}`);
    // Intégration Twilio / WhatsApp Business API ici
  }

  private async _sendSms(phone: string, message: string) {
    this.logger.log(`[SMS] Envoi à ${phone}: ${message}`);
    // Intégration Africa's Talking / Twilio ici
  }

  private async _simulateClaude(request: DiagnosticRequest) {
    await new Promise(resolve => setTimeout(resolve, 2000));
    request.aiResult = {
      label: 'Cercosporiose de l\'arachide',
      confidence: 0.92,
      suggestedSymptoms: ['taches_rondes_brunes', 'jaunissement_bordure'],
      recommendations: 'Utiliser un fongicide systémique et éviter l\'irrigation par aspersion.',
    };
    request.status = DiagnosticStatus.ANALYZED;
    await this.repository.save(request);
  }

  private async _getImageBase64(url: string): Promise<string> {
    // Dans un cas réel, on télécharge l'image depuis S3 ou le path local
    return 'BASE64_STUB';
  }

  async findAll(): Promise<DiagnosticRequest[]> {
    const results = await this.repository.find({ order: { createdAt: 'DESC' } });
    return results.map(r => ({
      ...r,
      photoUrl: r.photoUrl && !r.photoUrl.includes('undefined') ? r.photoUrl : null,
    }));
  }
}
