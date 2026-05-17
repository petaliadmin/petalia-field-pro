import { Module, Global } from '@nestjs/common';
import { PushNotificationService } from './push-notification.service';
import { NotificationsController } from './notifications.controller';
import { UsersModule } from '../users/users.module';

@Global()
@Module({
  imports: [UsersModule],
  controllers: [NotificationsController],
  providers: [PushNotificationService],
  exports: [PushNotificationService],
})
export class NotificationsModule {}
