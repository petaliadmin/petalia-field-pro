import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MulterModule } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';
import { DiagnosticsService } from './diagnostics.service';
import { DiagnosticsController } from './diagnostics.controller';
import { DiagnosticRequest } from './entities/diagnostic-request.entity';
import { Parcel } from '../parcels/entities/parcel.entity';
import { User } from '../users/entities/user.entity';
import { ImageAnalysisService } from './image-analysis.service';
import { WalletModule } from '../wallet/wallet.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([DiagnosticRequest, Parcel, User]),
    WalletModule,
    MulterModule.register({
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads'),
        filename: (_req, file, cb) => {
          cb(null, `${randomUUID()}${extname(file.originalname)}`);
        },
      }),
      limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
    }),
  ],
  controllers: [DiagnosticsController],
  providers: [DiagnosticsService, ImageAnalysisService],
  exports: [DiagnosticsService, ImageAnalysisService],
})
export class DiagnosticsModule {}
