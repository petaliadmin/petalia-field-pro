import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ParcelsService } from './parcels.service';
import { ParcelsController } from './parcels.controller';
import { Parcel } from './entities/parcel.entity';
import { SyncOutbox } from './entities/sync-outbox.entity';
import { DocumentService } from './document.service';
import { AgroService } from './agro.service';
import { GeospatialModule } from '../geospatial/geospatial.module';

@Module({
  imports: [TypeOrmModule.forFeature([Parcel, SyncOutbox]), GeospatialModule],
  controllers: [ParcelsController],
  providers: [ParcelsService, DocumentService, AgroService],
  exports: [ParcelsService, DocumentService, AgroService],
})
export class ParcelsModule {}
