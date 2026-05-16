import { Controller, Get, Post, Body, UseGuards, Request, UseInterceptors } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IdempotencyInterceptor } from '../common/interceptors/idempotency.interceptor';

@ApiTags('Wallet')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wallet')
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('balance')
  @ApiOperation({ summary: 'Récupérer le solde actuel de crédits' })
  async getBalance(@Request() req) {
    const userId = req.user?.id || '1b8dc7ab-7282-4a29-9abe-dddb0228d882';
    const balance = await this.walletService.getBalance(userId);
    return { balance };
  }

  @Post('topup')
  @UseInterceptors(IdempotencyInterceptor)
  @ApiOperation({ summary: 'Recharger son compte (Simulation)' })
  async topup(@Request() req, @Body() body: { amount: number; reference: string; description: string }) {
    const userId = req.user?.id || '1b8dc7ab-7282-4a29-9abe-dddb0228d882';
    return this.walletService.addCredits(userId, body.amount, body.description, body.reference);
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Récupérer l\'historique complet des transactions' })
  async getTransactions(@Request() req) {
    const userId = req.user?.id || '1b8dc7ab-7282-4a29-9abe-dddb0228d882';
    const transactions = await this.walletService.getTransactions(userId);
    return { transactions };
  }

  @Post('transfer')
  @UseInterceptors(IdempotencyInterceptor)
  @ApiOperation({ summary: 'Transférer des crédits à un autre producteur' })
  async transfer(
    @Request() req,
    @Body() body: { recipientPhone: string; amount: number; description?: string },
  ) {
    const userId = req.user?.id || '1b8dc7ab-7282-4a29-9abe-dddb0228d882';
    return this.walletService.transferCredits(
      userId,
      body.recipientPhone,
      body.amount,
      body.description,
    );
  }
}
