import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

export const ALL_METRICS = ['NDVI', 'NDWI', 'CLOUD', 'TILES', 'ALERTS', 'NDRE', 'SAVI', 'EVI2'];

export interface AnalysisResult {
  analysisId: string;
  fieldId: string;
  status: 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED';
  vegetation?: {
    meanNdvi: number;
    minNdvi: number;
    maxNdvi: number;
    stdNdvi: number;
    ndreeMean?: number;
    saviMean?: number;
    evi2Mean?: number;
    trend: 'UP' | 'DOWN' | 'STABLE' | 'UNKNOWN';
    health: 'EXCELLENT' | 'GOOD' | 'MODERATE' | 'POOR';
  };
  water?: { meanNdmi: number };
  cloudCoverage?: number;
  alerts?: Array<{
    severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
    type: string;
    message: string;
    createdAt: string;
  }>;
  visualization?: { tileUrl?: string; thumbnailUrl?: string };
  createdAt: string;
  completedAt?: string;
}

@Injectable()
export class GeospatialService {
  private readonly logger = new Logger(GeospatialService.name);
  private readonly baseUrl: string;
  private readonly apiKey: string;
  private readonly pollIntervalMs: number;
  private readonly analysisTimeoutMs: number;

  constructor(private readonly httpService: HttpService, private readonly config: ConfigService) {
    this.baseUrl = this.config.get<string>('GEO_ENGINE_URL') || 'http://localhost:8000';
    this.apiKey = this.config.get<string>('GEO_ENGINE_API_KEY') || '';
    this.pollIntervalMs = parseInt(this.config.get<string>('GEO_ENGINE_POLL_INTERVAL_MS') || '5000');
    this.analysisTimeoutMs = parseInt(this.config.get<string>('GEO_ENGINE_ANALYSIS_TIMEOUT_MS') || '120000');
  }

  private getHeaders(): Record<string, string> {
    const headers: Record<string, string> = {};
    if (this.apiKey) headers['X-API-Key'] = this.apiKey;
    return headers;
  }

  /**
   * Submits a new analysis to the engine (async — returns analysisId immediately).
   * The engine responds 202 Accepted; use pollAnalysis() to wait for completion.
   */
  async triggerAnalysis(
    fieldId: string,
    geometry: any,
    metrics: string[] = ALL_METRICS,
  ): Promise<string> {
    const url = `${this.baseUrl}/v1/analyses`;
    const payload = { fieldId, geometry, requestedMetrics: metrics };
    const response = await firstValueFrom(
      this.httpService.post(url, payload, { headers: this.getHeaders() }),
    );
    const analysisId: string = response.data?.analysisId;
    if (!analysisId) throw new Error(`Engine did not return an analysisId for field ${fieldId}`);
    this.logger.log(`Analysis triggered: ${analysisId} for field ${fieldId}`);
    return analysisId;
  }

  /**
   * Polls GET /v1/analyses/{id} every pollIntervalMs until status is COMPLETED or FAILED.
   * Throws if the analysis fails or the timeout is reached.
   */
  async pollAnalysis(analysisId: string, timeoutMs = this.analysisTimeoutMs): Promise<AnalysisResult> {
    const url = `${this.baseUrl}/v1/analyses/${analysisId}`;
    const deadline = Date.now() + timeoutMs;

    while (Date.now() < deadline) {
      const response = await firstValueFrom(
        this.httpService.get(url, { headers: this.getHeaders() }),
      );
      const data: AnalysisResult = response.data;

      if (data.status === 'COMPLETED') {
        this.logger.log(`Analysis completed: ${analysisId}`);
        return data;
      }
      if (data.status === 'FAILED') {
        throw new Error(`Analysis ${analysisId} failed in the GEE engine`);
      }

      await new Promise(r => setTimeout(r, this.pollIntervalMs));
    }
    throw new Error(`Analysis ${analysisId} timed out after ${timeoutMs}ms`);
  }

  /**
   * Convenience: trigger + poll in one call.
   * Use for on-demand analysis requests (controller endpoints).
   */
  async analyzeParcel(
    fieldId: string,
    geometry: any,
    metrics: string[] = ALL_METRICS,
  ): Promise<AnalysisResult> {
    const analysisId = await this.triggerAnalysis(fieldId, geometry, metrics);
    return this.pollAnalysis(analysisId);
  }

  /**
   * Submits up to 50 parcels in a single batch request.
   * Returns immediately with a batch summary (no polling — engine runs tasks async).
   */
  async batchAnalyze(
    fields: Array<{ fieldId: string; geometry: any }>,
    metrics: string[] = ['NDVI', 'NDWI', 'CLOUD', 'TILES', 'ALERTS'],
  ): Promise<{ submitted: number; succeeded: number; failed: number; items: any[] }> {
    if (fields.length === 0) return { submitted: 0, succeeded: 0, failed: 0, items: [] };
    const url = `${this.baseUrl}/v1/analyses/batch`;
    const payload = {
      fields: fields.map(f => ({ fieldId: f.fieldId, geometry: f.geometry, requestedMetrics: metrics })),
    };
    const response = await firstValueFrom(
      this.httpService.post(url, payload, { headers: this.getHeaders() }),
    );
    return response.data;
  }

  /**
   * Retrieves the latest completed analysis for a field (cached 24h in the engine's Redis).
   */
  async getFieldLatest(fieldId: string): Promise<AnalysisResult> {
    const url = `${this.baseUrl}/v1/fields/${fieldId}/latest`;
    const response = await firstValueFrom(this.httpService.get(url, { headers: this.getHeaders() }));
    if (!response.data) throw new Error(`Empty response from GEE engine for field ${fieldId}`);
    return response.data;
  }

  async getFieldAlerts(fieldId: string): Promise<any> {
    const url = `${this.baseUrl}/v1/fields/${fieldId}/alerts`;
    const response = await firstValueFrom(this.httpService.get(url, { headers: this.getHeaders() }));
    if (!response.data) throw new Error(`Empty alerts response from GEE engine for field ${fieldId}`);
    return response.data;
  }

  async getFieldTiles(fieldId: string): Promise<any> {
    const url = `${this.baseUrl}/v1/fields/${fieldId}/tiles`;
    const response = await firstValueFrom(this.httpService.get(url, { headers: this.getHeaders() }));
    if (!response.data) throw new Error(`Empty tiles response from GEE engine for field ${fieldId}`);
    return response.data;
  }

  async getFieldTimeseries(fieldId: string, limit = 30, offset = 0): Promise<any> {
    const url = `${this.baseUrl}/v1/fields/${fieldId}/timeseries?limit=${limit}&offset=${offset}`;
    const response = await firstValueFrom(this.httpService.get(url, { headers: this.getHeaders() }));
    if (!response.data) throw new Error(`Empty timeseries response from GEE engine for field ${fieldId}`);
    return response.data;
  }

  /**
   * Proxies an authenticated GEE URL (thumbnail or map tile) through the backend.
   * The frontend never contacts GEE directly — auth is handled server-side.
   */
  async proxyGeeUrl(targetUrl: string): Promise<{ buffer: Buffer; contentType: string }> {
    const response = await firstValueFrom(
      this.httpService.get(targetUrl, {
        headers: this.getHeaders(),
        responseType: 'arraybuffer',
      }),
    );
    const contentType = (response.headers['content-type'] as string) || 'image/png';
    return { buffer: Buffer.from(response.data), contentType };
  }
}
