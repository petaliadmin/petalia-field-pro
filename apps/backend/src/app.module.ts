import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ParcelsModule } from './parcels/parcels.module';
import { ExpertsModule } from './experts/experts.module';
import { AuthModule } from './auth/auth.module';
import { BotModule } from './bot/bot.module';
import { WalletModule } from './wallet/wallet.module';
import { DiagnosticsModule } from './diagnostics/diagnostics.module';
import { UsersModule } from './users/users.module';
import { PaymentModule } from './payment/payment.module';
import { UssdModule } from './ussd/ussd.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { TerminusModule } from '@nestjs/terminus';
import { HealthController } from './health.controller';
import { AuditInterceptor } from './common/interceptors/audit.interceptor';
import { BullModule } from '@nestjs/bull';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { SentryModule } from '@sentry/nestjs/setup';
import { IdempotencyInterceptor } from './common/interceptors/idempotency.interceptor';
import { RedisModule } from './redis/redis.module';
import { SystemModule } from './system/system.module';

import { WinstonModule } from 'nest-winston';
import * as winston from 'winston';

@Module({
  imports: [
    EventEmitterModule.forRoot(),
    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
      },
    }),
    SentryModule.forRoot(),
    WinstonModule.forRoot({
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.colorize(),
            winston.format.printf(({ timestamp, level, message, context }) => {
              return `${timestamp} [${context}] ${level}: ${message}`;
            }),
          ),
        }),
      ],
    }),
    TerminusModule,
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 10,
      },
    ]),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.get<string>('DATABASE_URL'),
        autoLoadEntities: true,
        synchronize: false, // Désactivé pour la sécurité du schéma en prod
      }),
      inject: [ConfigService],
    }),
    RedisModule,
    SystemModule,
    NotificationsModule,
    ParcelsModule,
    ExpertsModule,
    AuthModule,
    BotModule,
    WalletModule,
    DiagnosticsModule,
    UsersModule,
    PaymentModule,
    UssdModule,
  ],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: AuditInterceptor,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: IdempotencyInterceptor,
    },
  ],
})
export class AppModule {}
