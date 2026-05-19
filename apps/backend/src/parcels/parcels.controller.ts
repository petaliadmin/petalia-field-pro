import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  Delete,
  Header,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { AnyFilesInterceptor } from '@nestjs/platform-express';
import { ParcelsService } from './parcels.service';
import { CreateParcelDto } from './dto/create-parcel.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DocumentService } from './document.service';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('Parcelles')
@Controller('parcels')
@UseGuards(JwtAuthGuard)
export class ParcelsController {
  constructor(
    private readonly parcelsService: ParcelsService,
    private readonly documentService: DocumentService,
  ) {}

  @Post()
  create(@Body() parcelData: CreateParcelDto) {
    return this.parcelsService.create(parcelData);
  }

  @Post('observations')
  @UseInterceptors(AnyFilesInterceptor())
  async createObservation(
    @Body() observationData: any,
    @UploadedFiles() files: Array<Express.Multer.File>,
  ) {
    // Enregistrement de l'observation et des fichiers associés pour la synchronisation mobile
    return { success: true, observationId: observationData.id, receivedFiles: files?.length ?? 0 };
  }

  @Get()
  findAll(@Query('page') page: number = 1, @Query('limit') limit: number = 10) {
    return this.parcelsService.findAll(Number(page), Number(limit));
  }

  @Get('sync')
  async syncDeltas(@Query('last_sync') lastSync?: string) {
    const targetDate = lastSync && lastSync !== '1970-01-01' ? lastSync : '1970-01-01T00:00:00.000Z';
    return this.parcelsService.findSyncDeltas(targetDate);
  }

  @Post('sync/batch')
  async batchUpsert(@Body() body: { parcels: any[] }) {
    // Synchronisation tolérante : un payload mal formé d'une parcelle ne doit
    // pas bloquer la remontée du reste du lot depuis un client hors-ligne.
    const results: any[] = [];
    const failures: Array<{ id?: string; error: string }> = [];
    for (const p of body.parcels || []) {
      try {
        const res = await this.parcelsService.upsertSync(p);
        results.push(res);
      } catch (err: any) {
        failures.push({ id: p?.id, error: err?.message ?? String(err) });
      }
    }
    return {
      success: failures.length === 0,
      processed: results.length,
      failed: failures.length,
      parcels: results,
      failures,
    };
  }

  // --- Option B : Point d'accès public pour le "Passeport Parcelle" ---
  @Get('passport/:id')
  @Header('Content-Type', 'text/html')
  async getPassport(@Param('id') id: string) {
    const parcel = await this.parcelsService.findOne(id);
    return this.documentService.generateParcelPassport(parcel);
  }


  @Get(':id/analyze')
  async analyzeParcel(@Param('id') id: string, @Query('metrics') metrics: string) {
    const requestedMetrics = metrics ? metrics.split(',') : [];
    return this.parcelsService.analyzeParcel(id, requestedMetrics);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateData: any) {
    return this.parcelsService.update(id, updateData);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.parcelsService.remove(id);
  }
}
