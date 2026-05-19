import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { GeospatialService } from './geospatial.service';

@Module({
  imports: [HttpModule],
  providers: [GeospatialService],
  exports: [GeospatialService],
})
export class GeospatialModule {}
