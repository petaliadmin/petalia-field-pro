import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

@Injectable()
export class WhatsAppWebhookGuard implements CanActivate {
  constructor(private configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const signature = request.headers['x-hub-signature-256'] as string;
    const appSecret = this.configService.get<string>('WHATSAPP_APP_SECRET');

    if (!signature || !appSecret) {
      throw new UnauthorizedException('Missing signature or secret');
    }

    const payload = JSON.stringify(request.body);
    const expectedSignature =
      'sha256=' +
      crypto.createHmac('sha256', appSecret).update(payload).digest('hex');

    if (signature !== expectedSignature) {
      throw new UnauthorizedException('Invalid signature');
    }

    return true;
  }
}
