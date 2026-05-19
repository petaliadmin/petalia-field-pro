import { Module } from '@nestjs/common';
import { AgroRulesController, NdviController, SystemController } from './system.controller';
import { SystemService } from './system.service';
import { ParcelsModule } from '../parcels/parcels.module';

@Module({
  imports: [ParcelsModule],
  controllers: [SystemController, NdviController, AgroRulesController],
  providers: [SystemService],
  exports: [SystemService],
})
export class SystemModule {}
