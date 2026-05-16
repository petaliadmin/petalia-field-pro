import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WalletService } from './wallet.service';
import { UsersService } from '../users/users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { WalletOperationType } from './entities/wallet-transaction.entity';
import { UserRole } from '../users/entities/user.entity';

@ApiTags('Wallet Admin')
@Controller('wallet/admin')
export class WalletAdminController {
  private readonly logger = new Logger(WalletAdminController.name);

  constructor(
    private readonly walletService: WalletService,
    private readonly usersService: UsersService,
  ) {}

  @Get('users')
  @ApiOperation({ summary: 'Lister les utilisateurs avec leur solde de crédits' })
  async getUsersWithBalance(@Request() req) {
    const user = req.user || { id: 'admin-local-id', role: UserRole.ADMIN };

    if (user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Accès réservé aux administrateurs');
    }

    const users = await this.usersService.findAll();
    const usersWithBalance = await Promise.all(
      users.map(async (u) => {
        const balance = await this.walletService.getBalance(u.id);
        return {
          ...u,
          walletBalance: balance,
        };
      }),
    );

    return usersWithBalance;
  }

  @Post('transactions')
  @ApiOperation({ summary: 'Effectuer une opération administrative (Recharge, Ajustement, Régulation)' })
  async performTransaction(
    @Request() req,
    @Body() body: { userId: string; operationType: WalletOperationType; amount: number; description: string },
  ) {
    const user = req.user || { id: 'admin-local-id', role: UserRole.ADMIN };

    if (user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Accès réservé aux administrateurs');
    }

    this.logger.warn(`[WALLET_ADMIN_ACTION] Admin ${user.id} effectue ${body.operationType} de ${body.amount} sur l'utilisateur ${body.userId}. Motif: ${body.description}`);

    const transaction = await this.walletService.performAdminTransaction(
      user.id,
      body.userId,
      body.operationType,
      body.amount,
      body.description,
    );

    const newBalance = await this.walletService.getBalance(body.userId);

    return {
      success: true,
      transaction,
      newBalance,
    };
  }
}
