import { Controller, Get, Param, Query, Logger } from '@nestjs/common';
import { SystemService } from './system.service';
import { ParcelsService } from '../parcels/parcels.service';

@Controller('system')
export class SystemController {
  constructor(private readonly systemService: SystemService) {}

  @Get('catalogs')
  getCatalogs(@Query('version') version?: string) {
    return this.systemService.getCatalogs(version);
  }
}

@Controller('v1/ndvi')
export class NdviController {
  private readonly logger = new Logger(NdviController.name);

  constructor(private readonly parcelsService: ParcelsService) {}

  @Get(':parcelId')
  async getNdvi(@Param('parcelId') parcelId: string, @Query('force') force?: string) {
    try {
      let result: any = null;

      // Si force n'est pas activé, essayer de récupérer la dernière analyse en cache
      if (force !== 'true') {
        try {
          result = await this.parcelsService.getLatestAnalysis(parcelId);
        } catch (e) {
          this.logger.log(`No latest analysis found, will request a new one.`);
        }
      }

      // Si aucune analyse en cache ou force est à true, lancer une nouvelle analyse
      if (!result) {
        result = await this.parcelsService.analyzeParcel(parcelId, [
          'NDVI',
          'NDWI',
          'CLOUD',
          'TILES',
          'ALERTS',
        ]);
      }
      
      // Adaptative parsing for various possible response formats from the geospatial engine
      let value = result?.metrics?.ndvi ?? result?.ndvi ?? result?.value ?? result?.vegetation?.meanNdvi;
      if (value && typeof value === 'object') {
        value = value.mean ?? value.value ?? value.average;
      }

      if (value !== undefined && value !== null && !isNaN(Number(value))) {
        return {
          value: +Number(value).toFixed(3),
          parcelId,
          fetchedAt: result?.analysisDate ?? new Date().toISOString(),
          source: 'external_engine',
        };
      }
    } catch (err: any) {
      this.logger.warn(
        `Failed to fetch NDVI from external engine for parcel ${parcelId}: ${err?.message ?? err}. Falling back to simulation.`,
      );
    }

    // Simulated NDVI fallback — deterministic per parcel to keep UI consistent
    const hash = parcelId.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
    const value = 0.35 + (hash % 100) / 220; // range ~0.35–0.80
    return {
      value: +value.toFixed(3),
      parcelId,
      fetchedAt: new Date().toISOString(),
      source: 'simulation_fallback',
    };
  }
}

@Controller('v1/agro_rules')
export class AgroRulesController {
  @Get()
  getAgroRules(@Query('since') since?: string) {
    return { schemaVersion: 1, updatedAt: new Date().toISOString(), rules: [] };
  }
}
