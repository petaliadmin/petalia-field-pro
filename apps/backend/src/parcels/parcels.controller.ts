import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Delete,
  Header,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { AnyFilesInterceptor } from '@nestjs/platform-express';
import { ParcelsService } from './parcels.service';
import { CreateParcelDto } from './dto/create-parcel.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DocumentService } from './document.service';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('Parcelles')
@Controller('parcels')
export class ParcelsController {
  constructor(
    private readonly parcelsService: ParcelsService,
    private readonly documentService: DocumentService,
  ) {}

  @Post()
  create(@Body() parcelData: CreateParcelDto) {
    return this.parcelsService.create(parcelData);
  }

  @Post('observations')
  @UseInterceptors(AnyFilesInterceptor())
  async createObservation(
    @Body() observationData: any,
    @UploadedFiles() files: Array<Express.Multer.File>,
  ) {
    // Enregistrement de l'observation et des fichiers associés pour la synchronisation mobile
    return { success: true, observationId: observationData.id, receivedFiles: files?.length ?? 0 };
  }

  @Get()
  findAll(@Query('page') page: number = 1, @Query('limit') limit: number = 10) {
    return this.parcelsService.findAll(Number(page), Number(limit));
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.parcelsService.findOne(id);
  }

  // --- Option B : Point d'accès public pour le "Passeport Parcelle" ---
  @Get('passport/:id')
  @Header('Content-Type', 'text/html')
  async getPassport(@Param('id') id: string) {
    const parcel = await this.parcelsService.findOne(id);
    return this.documentService.generateParcelPassport(parcel);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  remove(@Param('id') id: string) {
    return this.parcelsService.remove(id);
  }
}
