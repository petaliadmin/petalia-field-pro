import { Module } from '@nestjs/common';
import { UssdController } from './ussd.controller';
import { UssdService } from './ussd.service';
import { UsersModule } from '../users/users.module';
import { WalletModule } from '../wallet/wallet.module';
import { SmsService } from '../common/services/sms.service';

@Module({
  imports: [UsersModule, WalletModule],
  controllers: [UssdController],
  providers: [UssdService, SmsService],
})
export class UssdModule {}
