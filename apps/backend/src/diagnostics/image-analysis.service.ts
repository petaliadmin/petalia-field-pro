import { Injectable, Logger, Inject } from '@nestjs/common';
import sharp from 'sharp';
import axios from 'axios';
import * as fs from 'fs';
import * as path from 'path';
import { Redis } from 'ioredis';

export interface ImageBiometrics {
  blurScore: number;       // 0 (flou) à 1 (net)
  chlorosisRatio: number;  // Pourcentage foliaire touché par la chlorose (jaunissement)
  necrosisRatio: number;   // Pourcentage foliaire touché par la nécrose (brunissement/taches)
  histogram: {
    r: number[];
    g: number[];
    b: number[];
  };
  dimensions: { width: number; height: number };
  analyzedAt: string;
}

@Injectable()
export class ImageAnalysisService {
  private readonly logger = new Logger(ImageAnalysisService.name);

  constructor(
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {}

  async analyzeImage(photoUrl: string | null, diagnosticId: string): Promise<ImageBiometrics> {
    const cacheKey = `image_biometrics:${diagnosticId}`;

    try {
      // 1. Vérification du cache Redis
      const cached = await this.redis.get(cacheKey);
      if (cached) {
        this.logger.log(`[Biometrics] Cache hit pour le diagnostic ${diagnosticId}`);
        return JSON.parse(cached);
      }
    } catch (err) {
      this.logger.warn(`Erreur lors de la lecture du cache Redis: ${err.message}`);
    }

    this.logger.log(`[Biometrics] Lancement de l'analyse d'image profonde pour ${photoUrl || 'STUB'}`);

    let buffer: Buffer;
    try {
      if (!photoUrl || photoUrl.includes('undefined')) {
        // Fallback / mock buffer pour les tests sans image réelle
        buffer = await sharp({
          create: { width: 400, height: 400, channels: 3, background: { r: 80, g: 160, b: 80 } },
        })
          .jpeg()
          .toBuffer();
      } else if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        const response = await axios.get(photoUrl, { responseType: 'arraybuffer' });
        buffer = Buffer.from(response.data);
      } else {
        const fullPath = path.resolve(process.cwd(), photoUrl.startsWith('/') ? photoUrl.slice(1) : photoUrl);
        if (fs.existsSync(fullPath)) {
          buffer = fs.readFileSync(fullPath);
        } else {
          buffer = await sharp({
            create: { width: 400, height: 400, channels: 3, background: { r: 80, g: 160, b: 80 } },
          })
            .jpeg()
            .toBuffer();
        }
      }
    } catch (e) {
      this.logger.warn(`Impossible de charger l'image (${photoUrl}), utilisation du buffer de secours. Erreur: ${e.message}`);
      buffer = await sharp({
        create: { width: 400, height: 400, channels: 3, background: { r: 80, g: 160, b: 80 } },
      })
        .jpeg()
        .toBuffer();
    }

    // 2. Extraction des données brutes RGB via sharp
    const { data, info } = await sharp(buffer)
      .resize(500, 500, { fit: 'inside', withoutEnlargement: true }) // Normalisation de la taille pour la rapidité
      .raw()
      .toBuffer({ resolveWithObject: true });

    const width = info.width;
    const height = info.height;
    const channels = info.channels;
    const totalPixels = width * height;

    // 3. Calcul de la variance du Laplacien (Blur Score) et des ratios foliaires
    const gray = new Float32Array(totalPixels);
    let healthyCount = 0;
    let chlorosisCount = 0;
    let necrosisCount = 0;

    const rHist = new Array(16).fill(0);
    const gHist = new Array(16).fill(0);
    const bHist = new Array(16).fill(0);

    for (let i = 0; i < totalPixels; i++) {
      const r = data[i * channels];
      const g = data[i * channels + 1];
      const b = data[i * channels + 2];

      // Luminance (Grayscale)
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;
      gray[i] = lum;

      // Histogramme (16 bins)
      rHist[Math.floor(r / 16)]++;
      gHist[Math.floor(g / 16)]++;
      bHist[Math.floor(b / 16)]++;

      // Heuristiques agronomiques de classification foliaire
      if (lum < 40) {
        // Taches noires / nécroses sévères
        necrosisCount++;
      } else if (g > r && g > b && g > 60) {
        // Tissu foliaire vert sain
        healthyCount++;
      } else if (r > g * 0.85 && r < g * 1.15 && r > 90 && b < 100) {
        // Jaunissement / Chlorose
        chlorosisCount++;
      } else if (r > g && g > b && lum > 40) {
        // Brunissement / Nécrose active
        necrosisCount++;
      }
    }

    // Calcul du Laplacien (Noyau 3x3)
    let laplacianSum = 0;
    let laplacianSqSum = 0;
    let lapCount = 0;

    for (let y = 1; y < height - 1; y++) {
      for (let x = 1; x < width - 1; x++) {
        const i = y * width + x;
        const val =
          gray[(y - 1) * width + x] +
          gray[(y + 1) * width + x] +
          gray[y * width + x - 1] +
          gray[y * width + x + 1] -
          4 * gray[i];
        laplacianSum += val;
        laplacianSqSum += val * val;
        lapCount++;
      }
    }

    const mean = laplacianSum / lapCount;
    const variance = (laplacianSqSum / lapCount) - mean * mean;
    const blurScore = Math.min(1, Math.max(0, variance / 500)); // Normalisation

    const biometrics: ImageBiometrics = {
      blurScore: parseFloat(blurScore.toFixed(2)),
      chlorosisRatio: parseFloat((chlorosisCount / totalPixels).toFixed(2)),
      necrosisRatio: parseFloat((necrosisCount / totalPixels).toFixed(2)),
      histogram: {
        r: rHist,
        g: gHist,
        b: bHist,
      },
      dimensions: { width, height },
      analyzedAt: new Date().toISOString(),
    };

    try {
      // Mise en cache pour 7 jours (7 * 24 * 60 * 60 = 604800 secondes)
      await this.redis.set(cacheKey, JSON.stringify(biometrics), 'EX', 604800);
      this.logger.log(`[Biometrics] Analyse terminée et mise en cache pour le diagnostic ${diagnosticId}`);
    } catch (err) {
      this.logger.warn(`Erreur lors de l'écriture dans le cache Redis: ${err.message}`);
    }

    return biometrics;
  }
}
