import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsObject,
  IsDate,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateParcelDto {
  @IsString()
  @IsNotEmpty()
  id: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  owner: string;

  @IsString()
  @IsOptional()
  village?: string;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsString()
  @IsOptional()
  technician?: string;

  @IsString()
  @IsNotEmpty()
  crop: string;

  @IsNumber()
  @IsOptional()
  healthScore?: number;

  @IsObject()
  @IsNotEmpty()
  boundary: any; // On pourrait valider plus finement le GeoJSON ici

  @IsNumber()
  @IsOptional()
  estimatedYield?: number;

  @IsDate()
  @Type(() => Date)
  @IsNotEmpty()
  lastVisit: Date;

  @IsString()
  @IsOptional()
  growthStage?: string;

  @IsString()
  @IsOptional()
  irrigation?: string;

  @IsString()
  @IsOptional()
  variety?: string;

  @IsOptional()
  semisDate?: any;

  @IsString()
  @IsOptional()
  region?: string;

  @IsString()
  @IsOptional()
  soilType?: string;

  @IsOptional()
  treatmentHistory?: any;
}
