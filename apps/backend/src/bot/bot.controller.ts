import { Controller, Post, Body, HttpCode } from '@nestjs/common';
import { BotService } from './bot.service';

@Controller('bot')
export class BotController {
  constructor(private readonly botService: BotService) {}

  @Post('whatsapp/webhook')
  @HttpCode(200)
  async handleWebhook(@Body() body: any) {
    // Dans un vrai scénario, on validerait la signature du webhook Meta
    return this.botService.processIncomingMessage(body);
  }
}
