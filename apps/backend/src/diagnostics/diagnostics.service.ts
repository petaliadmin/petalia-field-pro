import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DiagnosticRequest, DiagnosticStatus } from './entities/diagnostic-request.entity';
import { CreateDiagnosticDto, ValidateDiagnosticDto } from './dto/diagnostic.dto';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class DiagnosticsService {
  private readonly logger = new Logger(DiagnosticsService.name);

  constructor(
    @InjectRepository(DiagnosticRequest)
    private readonly repository: Repository<DiagnosticRequest>,
    private readonly configService: ConfigService,
  ) {}

  async create(createDto: CreateDiagnosticDto, photoUrl: string): Promise<DiagnosticRequest> {
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

      // Appel réel à Claude 3.5 Sonnet (Vision)
      const response = await axios.post(
        'https://api.anthropic.com/v1/messages',
        {
          model: 'claude-3-5-sonnet-20240620',
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: 'image/jpeg',
                    data: await this._getImageBase64(request.photoUrl),
                  },
                },
                {
                  type: 'text',
                  text: 'Analyse cette image de plante et identifie la maladie. Réponds au format JSON strict avec les champs: label (nom maladie), confidence (0-1), suggestedSymptoms (liste), recommendations (texte court).',
                },
              ],
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

    return saved;
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
