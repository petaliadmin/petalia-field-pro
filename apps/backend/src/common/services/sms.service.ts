import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Twilio } from 'twilio';

@Injectable()
export class SmsService {
  private twilioClient: Twilio;
  private readonly logger = new Logger(SmsService.name);

  constructor(private configService: ConfigService) {
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN');
    
    if (accountSid && authToken) {
      try {
        this.twilioClient = new Twilio(accountSid, authToken);
      } catch (error) {
        this.logger.warn(`Twilio init failed: ${error.message}. SMS will be logged but not sent.`);
      }
    } else {
      this.logger.warn('Twilio credentials not found. SMS will be logged but not sent.');
    }
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const message = `Votre code de vérification Petalia est : ${code}. Valide pendant 5 minutes.`;
    
    // Affichage systématique et bien visible du code OTP dans les logs
    this.logger.log(`====================================================`);
    this.logger.log(`[CODE OTP GENERE] Téléphone: ${phone} | Code: ${code}`);
    this.logger.log(`====================================================`);

    if (this.twilioClient) {
      try {
        await this.twilioClient.messages.create({
          body: message,
          from: this.configService.get<string>('TWILIO_PHONE_NUMBER'),
          to: phone,
        });
        this.logger.log(`SMS OTP envoyé avec succès à ${phone}`);
      } catch (error) {
        this.logger.error(`Échec de l'envoi Twilio à ${phone}: ${error.message}`);
        this.logger.log(`[MODE DÉGRADÉ/DEV] Code utilisable pour ${phone} : ${code}`);
      }
    } else {
      this.logger.log(`[SIMULATION SMS] Code pour ${phone} : ${code}`);
    }
  }

  async sendSms(phone: string, message: string): Promise<void> {
    this.logger.log(`====================================================`);
    this.logger.log(`[ENVOI SMS PUSH] Téléphone: ${phone} | Message: ${message}`);
    this.logger.log(`====================================================`);

    if (this.twilioClient) {
      try {
        await this.twilioClient.messages.create({
          body: message,
          from: this.configService.get<string>('TWILIO_PHONE_NUMBER'),
          to: phone,
        });
        this.logger.log(`SMS envoyé avec succès à ${phone}`);
      } catch (error) {
        this.logger.error(`Échec de l'envoi Twilio à ${phone}: ${error.message}`);
      }
    } else {
      this.logger.log(`[SIMULATION SMS] Message pour ${phone} : ${message}`);
    }
  }
}

