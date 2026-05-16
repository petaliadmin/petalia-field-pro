import { Controller, Post, Body, HttpCode } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { UssdService } from './ussd.service';

@ApiTags('USSD')
@Controller('ussd')
export class UssdController {
  constructor(private readonly ussdService: UssdService) {}

  @Post()
  @HttpCode(200)
  @ApiOperation({ summary: 'Endpoint de callback pour la passerelle USSD (ex. Africa Talking, Hub2)' })
  async handleUssdCallback(
    @Body() body: { sessionId: string; serviceCode: string; phoneNumber: string; text: string },
  ): Promise<string> {
    return this.ussdService.processUssdRequest(
      body.sessionId || `SESSION_${Date.now()}`,
      body.phoneNumber || '+221777443663',
      body.text ?? '',
    );
  }
}
