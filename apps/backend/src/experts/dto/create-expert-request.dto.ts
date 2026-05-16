import { IsString, IsNotEmpty, IsUUID, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateExpertRequestDto {
  @ApiProperty({ description: 'ID de la parcelle concernée' })
  @IsUUID()
  @IsNotEmpty()
  parcelId: string;

  @ApiProperty({ description: "ID de l'expert sollicité" })
  @IsUUID()
  @IsNotEmpty()
  expertId: string;
}
