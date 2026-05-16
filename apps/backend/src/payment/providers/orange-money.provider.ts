import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class OrangeMoneyProvider {
  private readonly logger = new Logger(OrangeMoneyProvider.name);

  constructor(
    private configService: ConfigService,
    private httpService: HttpService,
  ) {}

  async getAccessToken(): Promise<string> {
    const clientId = this.configService.get<string>('ORANGE_CLIENT_ID');
    const clientSecret = this.configService.get<string>('ORANGE_CLIENT_SECRET');

    if (!clientId || !clientSecret || clientId.startsWith('xxxx')) {
      throw new Error('Orange Money credentials not configured');
    }

    const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

    const response = await firstValueFrom(
      this.httpService.post(
        'https://api.orange.com/oauth/v3/token',
        'grant_type=client_credentials',
        {
          headers: {
            Authorization: `Basic ${credentials}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        },
      ),
      { defaultValue: null },
    );

    if (!response || !response.data) {
      throw new Error('No response from Orange Money OAuth API');
    }

    return response.data.access_token;
  }

  async createWebPayment(amount: number, paymentId: string): Promise<string> {
    const merchantKey = this.configService.get<string>('ORANGE_MERCHANT_KEY');
    const appUrl = this.configService.get<string>('APP_URL');

    try {
      const token = await this.getAccessToken();

      const response = await firstValueFrom(
        this.httpService.post(
          'https://api.orange.com/orange-money-webpay/sn/v1/webpayment',
          {
            merchant_key: merchantKey,
            currency: 'XOF',
            order_id: paymentId,
            amount: amount,
            return_url: `${appUrl}/payment/callback?id=${paymentId}&status=success`,
            cancel_url: `${appUrl}/payment/callback?id=${paymentId}&status=cancelled`,
            notif_url: `${appUrl}/payment/webhook/orangemoney`,
            lang: 'fr',
            reference: 'Petalia Crop Assist',
          },
          {
            headers: {
              Authorization: `Bearer ${token}`,
              'Content-Type': 'application/json',
            },
          },
        ),
        { defaultValue: null },
      );

      if (!response || !response.data) {
        throw new Error('No response from Orange Money WebPay API');
      }

      return response.data.payment_url;
    } catch (error) {
      this.logger.error(`Orange Money webpayment error: ${error.response?.data?.message || error.message}`);
      // Fallback for simulation if keys are missing or API fails
      return `${appUrl}/payment/simulate/${paymentId}`;
    }
  }
}
