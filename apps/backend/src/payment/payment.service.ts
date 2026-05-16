import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Payment, PaymentMethod, PaymentStatus } from './entities/payment.entity';
import { InitializePaymentDto, PaymentResponse } from './payment.dto';
import { WalletService } from '../wallet/wallet.service';
import { ConfigService } from '@nestjs/config';
import { WaveProvider } from './providers/wave.provider';
import { OrangeMoneyProvider } from './providers/orange-money.provider';

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);

  constructor(
    @InjectRepository(Payment)
    private paymentRepository: Repository<Payment>,
    private walletService: WalletService,
    private configService: ConfigService,
    private waveProvider: WaveProvider,
    private orangeMoneyProvider: OrangeMoneyProvider,
  ) {}

  async initializePayment(userId: string, dto: InitializePaymentDto): Promise<PaymentResponse> {
    const payment = this.paymentRepository.create({
      userId,
      amount: dto.amount,
      credits: dto.credits,
      method: dto.method,
      status: PaymentStatus.PENDING,
    });

    await this.paymentRepository.save(payment);

    let paymentUrl = '';
    const baseUrl = this.configService.get('APP_URL') || 'http://localhost:3000';

    if (dto.method === PaymentMethod.WAVE) {
      paymentUrl = await this.waveProvider.createCheckoutSession(dto.amount, payment.id);
    } else if (dto.method === PaymentMethod.ORANGE_MONEY) {
      paymentUrl = await this.orangeMoneyProvider.createWebPayment(dto.amount, payment.id);
    } else {
      paymentUrl = `${baseUrl}/payment/simulate/${payment.id}`;
    }

    payment.paymentUrl = paymentUrl;
    await this.paymentRepository.save(payment);

    return {
      paymentId: payment.id,
      paymentUrl: paymentUrl,
    };
  }


  async handleWebhook(paymentId: string, status: PaymentStatus, externalId?: string) {
    const payment = await this.paymentRepository.findOne({ where: { id: paymentId } });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.status !== PaymentStatus.PENDING) {
      this.logger.warn(`Payment ${paymentId} already processed with status ${payment.status}`);
      return;
    }

    payment.status = status;
    if (externalId) payment.externalId = externalId;
    await this.paymentRepository.save(payment);

    if (status === PaymentStatus.SUCCESS) {
      await this.walletService.addCredits(
        payment.userId,
        payment.credits,
        `Achat de crédits via ${payment.method}`,
        payment.id,
      );
      this.logger.log(`Credits added for user ${payment.userId} after successful ${payment.method} payment`);
    }
  }

  async getPaymentStatus(paymentId: string): Promise<Payment> {
    const payment = await this.paymentRepository.findOne({ where: { id: paymentId } });
    if (!payment) throw new NotFoundException('Payment not found');
    return payment;
  }
}
