import { Injectable, Logger } from '@nestjs/common';
import { createWriteStream } from 'fs';
import { join } from 'path';
import sharp from 'sharp';
import { randomBytes } from 'crypto';

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);
  private readonly uploadPath = join(process.cwd(), 'uploads');

  async savePhoto(file: Express.Multer.File): Promise<string> {
    const filename = `${randomBytes(8).toString('hex')}.webp`;
    const fullPath = join(this.uploadPath, filename);

    this.logger.log(`Processing photo: ${file.originalname} -> ${filename}`);

    // Redimensionnement et conversion en WebP pour économiser la bande passante mobile
    await sharp(file.buffer)
      .resize(1024, 1024, { fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 80 })
      .toFile(fullPath);

    return filename;
  }
}
