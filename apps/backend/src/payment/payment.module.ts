import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { Payment } from './entities/payment.entity';
import { PaymentService } from './payment.service';
import { PaymentController } from './payment.controller';
import { WalletModule } from '../wallet/wallet.module';
import { WaveProvider } from './providers/wave.provider';
import { OrangeMoneyProvider } from './providers/orange-money.provider';

@Module({
  imports: [
    TypeOrmModule.forFeature([Payment]),
    HttpModule,
    WalletModule,
  ],
  providers: [PaymentService, WaveProvider, OrangeMoneyProvider],
  controllers: [PaymentController],
  exports: [PaymentService],
})
export class PaymentModule {}
