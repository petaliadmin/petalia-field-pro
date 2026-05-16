import { Controller, Get, Query } from '@nestjs/common';
import { SystemService } from './system.service';

@Controller('system')
export class SystemController {
  constructor(private readonly systemService: SystemService) {}

  @Get('catalogs')
  getCatalogs(@Query('version') version?: string) {
    return this.systemService.getCatalogs(version);
  }
}
