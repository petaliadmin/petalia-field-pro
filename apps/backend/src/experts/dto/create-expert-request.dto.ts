import { IsString, IsNotEmpty, IsUUID, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateExpertRequestDto {
  @ApiProperty({ description: 'ID de la parcelle concernée' })
  @IsUUID()
  @IsNotEmpty()
  parcelId: string;

  @ApiProperty({ description: "ID de l'expert sollicité (optionnel, assigné par l'admin)" })
  @IsUUID()
  @IsOptional()
  expertId?: string;

  @ApiProperty({ description: 'Contexte de la visite (stade, symptômes, notes)', required: false })
  @IsString()
  @IsOptional()
  context?: string;

  @ApiProperty({ description: 'ID local généré par le mobile (ignoré, conservé pour idempotence)', required: false })
  @IsUUID()
  @IsOptional()
  id?: string;
}
