import { IsEnum, IsInt, Min } from 'class-validator';
import { PaymentMethod } from './entities/payment.entity';

export class InitializePaymentDto {
  @IsInt()
  @Min(100)
  amount: number;

  @IsInt()
  @Min(1)
  credits: number;

  @IsEnum(PaymentMethod)
  method: PaymentMethod;
}

export interface PaymentResponse {
  paymentId: string;
  paymentUrl: string;
}
