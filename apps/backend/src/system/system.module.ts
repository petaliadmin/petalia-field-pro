import { Module } from '@nestjs/common';
import { AgroRulesController, NdviController, SystemController } from './system.controller';
import { SystemService } from './system.service';

@Module({
  controllers: [SystemController, NdviController, AgroRulesController],
  providers: [SystemService],
  exports: [SystemService],
})
export class SystemModule {}
