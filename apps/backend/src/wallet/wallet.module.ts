import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WalletService } from './wallet.service';
import { WalletController } from './wallet.controller';
import { WalletAdminController } from './wallet-admin.controller';
import { WalletTransaction } from './entities/wallet-transaction.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([WalletTransaction]), UsersModule],
  providers: [WalletService],
  controllers: [WalletController, WalletAdminController],
  exports: [WalletService],
})
export class WalletModule {}
