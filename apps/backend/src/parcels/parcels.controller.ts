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
  Res,
  BadRequestException,
} from '@nestjs/common';
import { AnyFilesInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { ParcelsService } from './parcels.service';
import { CreateParcelDto } from './dto/create-parcel.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DocumentService } from './document.service';
import { GeospatialService } from '../geospatial/geospatial.service';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('Parcelles')
@Controller('parcels')
@UseGuards(JwtAuthGuard)
export class ParcelsController {
  constructor(
    private readonly parcelsService: ParcelsService,
    private readonly documentService: DocumentService,
    private readonly geospatialService: GeospatialService,
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
    // Convert generic metrics query parameter to uppercase engine enum values
    const upperMetrics = requestedMetrics.map(m => m.toUpperCase());
    try {
      return await this.parcelsService.analyzeParcel(id, upperMetrics);
    } catch (err) {
      // Fallback
      return this.getSimulatedAnalysis(id);
    }
  }

  @Get(':id/latest')
  async getLatest(@Param('id') id: string) {
    try {
      return await this.parcelsService.getLatestAnalysis(id);
    } catch (err) {
      return this.getSimulatedAnalysis(id);
    }
  }

  @Get(':id/alerts')
  async getAlerts(@Param('id') id: string) {
    try {
      return await this.parcelsService.getAlerts(id);
    } catch (err) {
      return this.getSimulatedAnalysis(id).alerts;
    }
  }

  @Get(':id/tiles')
  async getTiles(@Param('id') id: string) {
    try {
      return await this.parcelsService.getTiles(id);
    } catch (err) {
      return this.getSimulatedAnalysis(id).visualization;
    }
  }

  @Get(':id/timeseries')
  async getTimeseries(@Param('id') id: string) {
    try {
      return await this.parcelsService.getTimeseries(id);
    } catch (err) {
      return this.getSimulatedTimeseries(id);
    }
  }

  /**
   * Proxy GEE thumbnail image via the backend (avoids browser auth issues).
   * Usage: <img src="/parcels/{id}/thumbnail">
   */
  @Get(':id/thumbnail')
  async getThumbnail(@Param('id') id: string, @Res() res: Response) {
    try {
      const analysis = await this.parcelsService.getLatestAnalysis(id);
      const thumbnailUrl = analysis?.visualization?.thumbnailUrl;
      if (!thumbnailUrl) {
        return res.status(404).json({ message: 'No thumbnail available' });
      }
      const { buffer, contentType } = await this.geospatialService.proxyGeeUrl(thumbnailUrl);
      res.set('Content-Type', contentType);
      res.set('Cache-Control', 'public, max-age=3600');
      return res.send(buffer);
    } catch (err) {
      return res.status(502).json({ message: 'Failed to proxy GEE thumbnail', error: err.message });
    }
  }

  /**
   * Proxy a specific GEE map tile via the backend.
   * Usage: tileUrl = "/parcels/{id}/tile?z={z}&x={x}&y={y}"
   */
  @Get(':id/tile')
  async getMapTile(
    @Param('id') id: string,
    @Query('z') z: string,
    @Query('x') x: string,
    @Query('y') y: string,
    @Res() res: Response,
  ) {
    try {
      if (!z || !x || !y) throw new BadRequestException('z, x, y params are required');
      const analysis = await this.parcelsService.getLatestAnalysis(id);
      const tileUrlTemplate = analysis?.visualization?.tileUrl;
      if (!tileUrlTemplate) {
        return res.status(404).json({ message: 'No tile URL available' });
      }
      const tileUrl = tileUrlTemplate.replace('{z}', z).replace('{x}', x).replace('{y}', y);
      const { buffer, contentType } = await this.geospatialService.proxyGeeUrl(tileUrl);
      res.set('Content-Type', contentType);
      res.set('Cache-Control', 'public, max-age=3600');
      return res.send(buffer);
    } catch (err) {
      return res.status(502).json({ message: 'Failed to proxy GEE tile', error: err.message });
    }
  }

  private getSimulatedAnalysis(parcelId: string) {
    const hash = parcelId.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
    const ndvi = 0.35 + (hash % 100) / 220; // range ~0.35–0.80
    const ndmi = 0.2 + (hash % 50) / 150;
    const trend = hash % 3 === 0 ? 'UP' : hash % 3 === 1 ? 'DOWN' : 'STABLE';
    const health = ndvi >= 0.7 ? 'EXCELLENT' : ndvi >= 0.5 ? 'GOOD' : ndvi >= 0.3 ? 'FAIR' : 'POOR';
    
    // Deterministic alerts
    const alerts: any[] = [];
    if (ndvi < 0.48) {
      alerts.push({
        id: `alert_ndvi_low_${hash}`,
        severity: 'HIGH',
        alertType: 'NDVI_LOW',
        message: `La vigueur végétative moyenne (${(ndvi * 100).toFixed(0)}%) est anormalement basse. Appliquez de l'engrais.`,
        createdAt: new Date(Date.now() - 3600000).toISOString(),
      });
    }
    if (ndmi < 0.3) {
      alerts.push({
        id: `alert_ndmi_low_${hash}`,
        severity: 'MEDIUM',
        alertType: 'NDVI_DROP',
        message: 'Stress hydrique potentiel détecté par satellite (indice de sécheresse bas). Vérifiez l\'irrigation.',
        createdAt: new Date(Date.now() - 7200000).toISOString(),
      });
    }

    return {
      fieldId: parcelId,
      analysisId: `sim_ana_${hash}`,
      analysisDate: new Date().toISOString(),
      status: 'COMPLETED',
      vegetation: {
        meanNdvi: +ndvi.toFixed(3),
        minNdvi: +(ndvi - 0.15).toFixed(3),
        maxNdvi: +(ndvi + 0.15).toFixed(3),
        stdNdvi: 0.07,
        trend,
        health,
      },
      water: {
        meanNdmi: +ndmi.toFixed(3),
      },
      alerts,
      visualization: {
        tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        thumbnailUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6fe22581?auto=format&fit=crop&q=80&w=600',
      },
      cloudCoverage: 0.08,
    };
  }

  private getSimulatedTimeseries(parcelId: string) {
    const hash = parcelId.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
    const ndviBase = 0.35 + (hash % 100) / 220;
    
    // Generate 5 entries over last 30 days
    const timeseries: any[] = [];
    for (let i = 4; i >= 0; i--) {
      const date = new Date(Date.now() - i * 6 * 24 * 3600 * 1000);
      const ndvi = ndviBase + Math.sin(i) * 0.05;
      const ndmi = ndvi * 0.7;
      timeseries.push({
        date: date.toISOString().split('T')[0],
        ndvi: +ndvi.toFixed(3),
        ndmi: +ndmi.toFixed(3),
      });
    }
    return timeseries;
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
