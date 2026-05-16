import { IsString, IsNotEmpty, IsOptional, IsBoolean } from 'class-validator';

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
  @IsBoolean()
  @IsOptional()
  approve?: boolean;

  @IsString()
  @IsOptional()
  comment?: string;

  @IsString()
  @IsOptional()
  adminComment?: string;
}
