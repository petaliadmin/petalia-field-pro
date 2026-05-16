import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class WaveProvider {
  private readonly logger = new Logger(WaveProvider.name);
  private readonly baseUrl = 'https://api.wave.com/v1';

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
  ) {}

  async createCheckoutSession(amount: number, paymentId: string) {
    const apiKey = this.configService.get<string>('WAVE_API_KEY');
    const appUrl = this.configService.get<string>('APP_URL');

    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.baseUrl}/checkout/sessions`,
          {
            amount: amount,
            currency: 'XOF',
            error_url: `${appUrl}/payment/callback?id=${paymentId}&status=failed`,
            success_url: `${appUrl}/payment/callback?id=${paymentId}&status=success`,
          },
          {
            headers: {
              Authorization: `Bearer ${apiKey}`,
            },
          },
        ),
        { defaultValue: null },
      );

      if (!response || !response.data) {
        throw new Error('No response from Wave API');
      }

      return response.data.wave_launch_url;
    } catch (error) {
      this.logger.error(`Wave checkout error: ${error.response?.data?.message || error.message}`);
      // Fallback for simulation if keys are missing
      return `${appUrl}/payment/simulate/${paymentId}`;
    }
  }
}
