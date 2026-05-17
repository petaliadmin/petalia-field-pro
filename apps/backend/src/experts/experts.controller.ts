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

  @Get('all-requests')
  @ApiOperation({ summary: 'Liste toutes les demandes d\'avis expert pour l\'administration' })
  async getAllRequests() {
    return this.expertsService.findAllRequests();
  }

  @Patch('request/:id/respond')
  @ApiOperation({ summary: 'Répondre à une demande d\'avis expert depuis l\'admin' })
  async respondToRequest(
    @Param('id') id: string,
    @Body() body: { expertAdvice: string; status?: 'completed' | 'cancelled' },
  ) {
    return this.expertsService.updateRequestStatus(id, body.expertAdvice, body.status || 'completed');
  }
}
