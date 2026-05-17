import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ExpertsController } from './experts.controller';
import { Expert, ExpertRequest } from './entities/expert.entity';
import { LedgerEntry } from './entities/ledger.entity';
import { ExpertsService } from './experts.service';
import { PaymentService } from './payment.service';
import { User } from '../users/entities/user.entity';
import { WalletModule } from '../wallet/wallet.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Expert, ExpertRequest, LedgerEntry, User]),
    WalletModule,
  ],
  controllers: [ExpertsController],
  providers: [ExpertsService, PaymentService],
  exports: [ExpertsService, PaymentService],
})
export class ExpertsModule {}
