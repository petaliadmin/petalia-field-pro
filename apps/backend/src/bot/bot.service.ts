import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { KnowledgeService } from './knowledge.service';

@Injectable()
export class BotService {
  private readonly logger = new Logger(BotService.name);
  private readonly openAiKey: string;
  private readonly whatsappToken: string;
  private readonly responseCache = new Map<string, string>();

  constructor(
    private configService: ConfigService,
    private knowledgeService: KnowledgeService,
  ) {
    this.openAiKey = this.configService.get<string>('OPENAI_API_KEY')!;
    this.whatsappToken = this.configService.get<string>('WHATSAPP_TOKEN')!;
  }

  async processIncomingMessage(body: any) {
    const message = body.entry?.[0]?.changes?.[0]?.value?.messages?.[0];
    if (!message) return { status: 'no_message' };

    const from = message.from;
    let textContent = '';

    try {
      if (message.type === 'audio') {
        textContent = await this.transcribeAudio(message.audio.id);
      } else if (message.type === 'text') {
        textContent = message.text.body;
      }

      if (textContent && this.openAiKey) {
        // Cache Check
        const cachedResponse = this.responseCache.get(
          textContent.toLowerCase(),
        );
        if (cachedResponse) {
          this.logger.log(`Cache hit for: ${textContent}`);
          await this.sendWhatsAppMessage(from, cachedResponse);
          return { status: 'cached' };
        }

        const response = await this.generateAgroAdvice(textContent);
        this.responseCache.set(textContent.toLowerCase(), response);
        await this.sendWhatsAppMessage(from, response);
      }
    } catch (error) {
      this.logger.error('Error in bot processing:', error.message);
      await this.sendWhatsAppMessage(
        from,
        'Désolé, Petalia Bot rencontre une erreur technique. Réessayez plus tard.',
      );
    }

    return { status: 'processed' };
  }

  private async transcribeAudio(mediaId: string): Promise<string> {
    this.logger.log(`Transcribing audio via Whisper for media ${mediaId}`);
    // Note: Dans une version prod complète, on télécharge d'abord le binaire depuis Meta
    // Ici on simule l'appel Whisper avec le buffer de l'audio
    if (!this.openAiKey) return 'Transcription impossible (Clé manquante)';

    const response = await axios.post(
      'https://api.openai.com/v1/audio/transcriptions',
      { file: mediaId, model: 'whisper-1', language: 'fr' }, // simplification
      { headers: { Authorization: `Bearer ${this.openAiKey}` } },
    );
    return response.data.text;
  }

  private async generateAgroAdvice(query: string): Promise<string> {
    this.logger.log(
      `Generating GPT-4o advice with local context for: ${query}`,
    );

    const localContext = this.knowledgeService.getLocalKnowledge(query);

    const response = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      {
        model: 'gpt-4o',
        messages: [
          {
            role: 'system',
            content: `Tu es un expert agronome spécialisé dans les cultures sahéliennes (Sénégal). ${localContext}`,
          },
          { role: 'user', content: query },
        ],
      },
      { headers: { Authorization: `Bearer ${this.openAiKey}` } },
    );

    return response.data.choices[0].message.content;
  }

  private async sendWhatsAppMessage(to: string, text: string) {
    if (!this.whatsappToken) {
      this.logger.warn('WhatsApp token missing, message not sent');
      return;
    }

    await axios.post(
      `https://graph.facebook.com/v17.0/${this.configService.get('WHATSAPP_PHONE_ID')}/messages`,
      {
        messaging_product: 'whatsapp',
        to,
        type: 'text',
        text: { body: text },
      },
      { headers: { Authorization: `Bearer ${this.whatsappToken}` } },
    );
  }
}
