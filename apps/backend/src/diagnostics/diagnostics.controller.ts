import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Patch,
  Request,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { DiagnosticsService } from './diagnostics.service';
import { CreateDiagnosticDto, ValidateDiagnosticDto } from './dto/diagnostic.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Diagnostics')
@Controller('diagnostics')
export class DiagnosticsController {
  constructor(private readonly diagnosticsService: DiagnosticsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(FileInterceptor('photo'))
  async create(
    @Request() req,
    @Body() createDto: CreateDiagnosticDto,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const photoUrl = file?.filename ? `uploads/${file.filename}` : null;
    const userId = req.user?.userId || req.user?.id;
    return this.diagnosticsService.create(createDto, photoUrl, userId);
  }

  @Get()
  async findAll() {
    return this.diagnosticsService.findAll();
  }

  @Get(':id/biometrics')
  async getBiometrics(@Param('id') id: string) {
    return this.diagnosticsService.getBiometrics(id);
  }

  @Patch(':id/validate')
  async validate(
    @Param('id') id: string,
    @Body() validateDto: ValidateDiagnosticDto,
  ) {
    return this.diagnosticsService.validate(id, validateDto);
  }
}
