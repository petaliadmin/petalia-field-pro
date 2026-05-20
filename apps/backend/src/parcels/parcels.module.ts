import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { ParcelsService } from './parcels.service';
import { ParcelsController } from './parcels.controller';
import { Parcel } from './entities/parcel.entity';
import { SyncOutbox } from './entities/sync-outbox.entity';
import { DocumentService } from './document.service';
import { AgroService } from './agro.service';
import { GeospatialModule } from '../geospatial/geospatial.module';
import { AnalysisSchedulerService } from './analysis-scheduler.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Parcel, SyncOutbox]),
    GeospatialModule,
    ScheduleModule.forRoot(),
  ],
  controllers: [ParcelsController],
  providers: [ParcelsService, DocumentService, AgroService, AnalysisSchedulerService],
  exports: [ParcelsService, DocumentService, AgroService],
})
export class ParcelsModule {}
