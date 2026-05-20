import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ParcelsService } from './parcels.service';
import { GeospatialService } from '../geospatial/geospatial.service';

const BATCH_SIZE = 50; // Engine limit per batch request

@Injectable()
export class AnalysisSchedulerService {
  private readonly logger = new Logger(AnalysisSchedulerService.name);

  constructor(
    private readonly parcelsService: ParcelsService,
    private readonly geospatialService: GeospatialService,
  ) {}

  /**
   * Runs every day at 02:00 AM. Submits all parcels with a boundary
   * to the geospatial engine in batches of 50 so NDVI data stays fresh.
   */
  @Cron('0 2 * * *', { name: 'daily-ndvi-batch', timeZone: 'Africa/Dakar' })
  async runDailyBatch(): Promise<void> {
    this.logger.log('Daily NDVI batch started');

    let processed = 0;
    let failed = 0;

    try {
      const { data: parcels } = await this.parcelsService.findAll(1, 5000);
      const withBoundary = parcels.filter(p => p.boundary);

      if (withBoundary.length === 0) {
        this.logger.log('No parcels with boundary found — skipping batch');
        return;
      }

      for (let i = 0; i < withBoundary.length; i += BATCH_SIZE) {
        const chunk = withBoundary.slice(i, i + BATCH_SIZE);
        try {
          const result = await this.geospatialService.batchAnalyze(
            chunk.map(p => ({ fieldId: p.id, geometry: p.boundary })),
          );
          processed += result.succeeded;
          failed += result.failed;
          this.logger.log(
            `Batch ${Math.floor(i / BATCH_SIZE) + 1}: submitted=${result.submitted} ok=${result.succeeded} fail=${result.failed}`,
          );
        } catch (err: any) {
          failed += chunk.length;
          this.logger.error(`Batch chunk failed: ${err?.message}`);
        }
      }
    } catch (err: any) {
      this.logger.error(`Daily NDVI batch aborted: ${err?.message}`);
    }

    this.logger.log(`Daily NDVI batch finished — processed=${processed} failed=${failed}`);
  }
}
