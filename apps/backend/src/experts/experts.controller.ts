import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ExpertsService } from './experts.service';
import { CreateExpertRequestDto } from './dto/create-expert-request.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Experts')
@Controller('experts')
export class ExpertsController {
  constructor(private readonly expertsService: ExpertsService) {}

  @Get()
  @ApiOperation({ summary: 'Liste tous les experts disponibles' })
  async getExperts() {
    return this.expertsService.findAll();
  }

  @Post('request')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Créer une demande d'assistance d'un expert" })
  async createRequest(@Body() dto: CreateExpertRequestDto) {
    return this.expertsService.createRequest(dto);
  }

  @Patch('request/:id/pay')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Confirmer le paiement d'une demande" })
  async confirmPayment(
    @Param('id') id: string,
    @Body('reference') reference: string,
  ) {
    return this.expertsService.confirmPayment(id, reference);
  }

  @Get('my-requests/:parcelId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Historique des demandes pour une parcelle donnée' })
  async getMyRequests(@Param('parcelId') parcelId: string) {
    return this.expertsService.findByParcel(parcelId);
  }
}
