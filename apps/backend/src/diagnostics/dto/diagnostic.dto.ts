import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateDiagnosticDto {
  @IsString()
  @IsNotEmpty()
  parcelId: string;

  @IsString()
  @IsNotEmpty()
  ownerName: string;

  @IsString()
  @IsNotEmpty()
  ownerPhone: string;
}

export class ValidateDiagnosticDto {
  @IsString()
  @IsOptional()
  adminComment?: string;
}
