import { Controller, Get, Param, Query } from '@nestjs/common';
import { SystemService } from './system.service';

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
  @Get(':parcelId')
  getNdvi(@Param('parcelId') parcelId: string) {
    // Simulated NDVI — deterministic per parcel to keep UI consistent
    const hash = parcelId.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
    const value = 0.35 + (hash % 100) / 220; // range ~0.35–0.80
    return { value: +value.toFixed(3), parcelId, fetchedAt: new Date().toISOString() };
  }
}

@Controller('v1/agro_rules')
export class AgroRulesController {
  @Get()
  getAgroRules(@Query('since') since?: string) {
    return { schemaVersion: 1, updatedAt: new Date().toISOString(), rules: [] };
  }
}
