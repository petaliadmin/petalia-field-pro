import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ExpertsController } from './experts.controller';
import { Expert, ExpertRequest } from './entities/expert.entity';
import { LedgerEntry } from './entities/ledger.entity';
import { ExpertsService } from './experts.service';
import { PaymentService } from './payment.service';

@Module({
  imports: [TypeOrmModule.forFeature([Expert, ExpertRequest, LedgerEntry])],
  controllers: [ExpertsController],
  providers: [ExpertsService, PaymentService],
  exports: [ExpertsService, PaymentService],
})
export class ExpertsModule {}
