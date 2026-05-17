import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { User } from '../users/entities/user.entity';

@Injectable()
export class PushNotificationService {
  private readonly logger = new Logger(PushNotificationService.name);

  constructor() {
    if (admin.apps.length === 0) {
      try {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        });
        this.logger.log('Firebase Admin SDK initialisé avec succès.');
      } catch (error) {
        this.logger.warn(`Initialisation de Firebase Admin SDK ignorée/simulée: ${error.message}`);
      }
    }
  }

  async sendPushToTechnician(user: User, title: string, body: string, data: any = {}): Promise<void> {
    this.logger.log(`[Push Notification] Préparation de l'envoi pour le technicien ${user.name} (ID: ${user.id})`);

    if (!user.fcmToken) {
      this.logger.warn(`Le technicien ${user.name} (ID: ${user.id}) n'a pas de token FCM configuré. Notification push ignorée.`);
      return;
    }

    const payload = {
      token: user.fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        sound: 'default',
      },
    };

    try {
      const response = await admin.messaging().send(payload);
      this.logger.log(`[Push Notification] Envoyée avec succès au technicien ${user.name} (FCM Message ID: ${response})`);
    } catch (error) {
      this.logger.error(`[Push Notification] Échec de l'envoi au technicien ${user.name} (Token: ${user.fcmToken}): ${error.message}`);
    }
  }
}
