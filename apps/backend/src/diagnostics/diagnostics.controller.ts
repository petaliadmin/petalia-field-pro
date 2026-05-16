import { Controller, Post, Body, Get, Param, Patch, UseInterceptors, UploadedFile } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { DiagnosticsService } from './diagnostics.service';
import { CreateDiagnosticDto, ValidateDiagnosticDto } from './dto/diagnostic.dto';

@Controller('diagnostics')
export class DiagnosticsController {
  constructor(private readonly diagnosticsService: DiagnosticsService) {}

  @Post()
  @UseInterceptors(FileInterceptor('photo'))
  async create(
    @Body() createDto: CreateDiagnosticDto,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const photoUrl = file?.filename ? `uploads/${file.filename}` : null;
    return this.diagnosticsService.create(createDto, photoUrl);
  }

  @Get()
  async findAll() {
    return this.diagnosticsService.findAll();
  }

  @Patch(':id/validate')
  async validate(
    @Param('id') id: string,
    @Body() validateDto: ValidateDiagnosticDto,
  ) {
    return this.diagnosticsService.validate(id, validateDto);
  }
}
