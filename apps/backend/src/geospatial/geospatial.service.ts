import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class GeospatialService {
  private readonly baseUrl: string;
  private readonly apiKey: string;

  constructor(private httpService: HttpService, private config: ConfigService) {
    this.baseUrl = this.config.get<string>('GEO_ENGINE_URL') || 'http://localhost:8000';
    this.apiKey = this.config.get<string>('GEO_ENGINE_API_KEY') || '';
  }

  /**
   * Sends a geometry payload to the external petalia‑geospacial‑engine.
   * The engine expects a POST to /v1/analyses with a CreateAnalysisRequest.
   * Returns the raw JSON response from the engine.
   */
  async analyzeParcel(geometry: any, requestedMetrics: string[] = []): Promise<any> {
    const url = `${this.baseUrl}/v1/analyses`;
    const payload = {
      fieldId: 'placeholder', // backend generates its own ID; engine does not need it
      geometry,
      requestedMetrics,
    };

    const headers: Record<string, string> = {};
    if (this.apiKey) {
      headers['X-API-Key'] = this.apiKey; // Header utilisé par le moteur géospatial pour l'authentification
    }

    const response$ = this.httpService.post(url, payload, { headers });
    const response = await firstValueFrom(response$);
    return response.data;
  }
}
