import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import { join } from 'path';

export interface StorageProvider {
  save(filename: string, buffer: Buffer): Promise<string>;
  getUrl(filename: string): string;
}

@Injectable()
export class LocalStorageProvider implements StorageProvider {
  private readonly uploadPath = join(process.cwd(), 'uploads');

  async save(filename: string, buffer: Buffer): Promise<string> {
    const fullPath = join(this.uploadPath, filename);
    await fs.promises.writeFile(fullPath, buffer);
    return filename;
  }

  getUrl(filename: string): string {
    return `/uploads/${filename}`;
  }
}
