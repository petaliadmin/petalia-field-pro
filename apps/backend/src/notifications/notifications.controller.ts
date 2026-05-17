import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PushNotificationService } from './push-notification.service';
import { UsersService } from '../users/users.service';

@ApiTags('Notifications Push')
@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly pushService: PushNotificationService,
    private readonly usersService: UsersService,
  ) {}

  @Post('send')
  @ApiOperation({ summary: 'Envoyer une notification push (individuelle ou collective)' })
  async sendPushNotification(
    @Body() body: {
      target: 'ALL' | 'INDIVIDUAL';
      userId?: string;
      fcmToken?: string;
      title: string;
      body: string;
      data?: any;
    },
  ) {
    if (!body.title || !body.body) {
      throw new BadRequestException('Le titre et le corps de la notification sont obligatoires.');
    }

    if (body.target === 'ALL') {
      const users = await this.usersService.findAll();
      const tokens = users.map(u => u.fcmToken).filter(t => !!t);
      if (tokens.length === 0) {
        return { success: false, message: 'Aucun appareil avec token FCM trouvé.' };
      }
      await this.pushService.sendPushMulticast(tokens, body.title, body.body, body.data);
      return { success: true, targetCount: tokens.length, message: 'Notification collective envoyée.' };
    } else if (body.target === 'INDIVIDUAL') {
      let token = body.fcmToken;
      if (!token && body.userId) {
        const user = await this.usersService.findOne(body.userId);
        token = user?.fcmToken;
      }
      if (!token) {
        throw new BadRequestException('Token FCM ou ID utilisateur valide obligatoire pour un envoi individuel.');
      }
      await this.pushService.sendPushToDevice(token, body.title, body.body, body.data);
      return { success: true, targetToken: token, message: 'Notification individuelle envoyée.' };
    } else {
      throw new BadRequestException('Cible invalide. Utilisez ALL ou INDIVIDUAL.');
    }
  }
}
