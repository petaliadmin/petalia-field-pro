import { Component, OnInit, Input, Output, EventEmitter, ElementRef, ViewChild, inject, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { DiagnosticService } from '../../core/services/diagnostic.service';

@Component({
  selector: 'app-advanced-image-analyzer',
  standalone: true,
  imports: [CommonModule, LucideAngularModule, FormsModule],
  templateUrl: './advanced-image-analyzer.component.html',
  styles: [`
    :host { display: block; }
  `]
})
export class AdvancedImageAnalyzerComponent implements OnInit, AfterViewInit {
  @Input() photoUrl: string = '';
  @Input() diagnosticId: string = '';
  @Input() title: string = 'Examen Agronomique Approfondi';
  @Output() close = new EventEmitter<void>();

  @ViewChild('canvas', { static: false }) canvasRef!: ElementRef<HTMLCanvasElement>;

  activeFilter: 'none' | 'chlorosis' | 'necrosis' | 'heatmap' = 'none';
  loupeEnabled = false;
  loupeX = 0;
  loupeY = 0;

  biometrics: any = null;
  isLoadingBiometrics = false;
  maxHistValue = 1;

  zoom = 1;
  panX = 0;
  panY = 0;
  isDragging = false;
  startX = 0;
  startY = 0;

  private ctx!: CanvasRenderingContext2D | null;
  private img = new Image();
  private offscreenCanvas = document.createElement('canvas');
  private offscreenCtx = this.offscreenCanvas.getContext('2d');
  private originalImageData: ImageData | null = null;

  private diagnosticService = inject(DiagnosticService);

  ngOnInit() {
    this.loadBiometrics();
  }

  ngAfterViewInit() {
    this.initCanvas();
  }

  loadBiometrics() {
    if (!this.diagnosticId) return;
    this.isLoadingBiometrics = true;
    this.diagnosticService.getBiometrics(this.diagnosticId).subscribe({
      next: (data) => {
        this.biometrics = data;
        this.isLoadingBiometrics = false;
        if (data && data.histogram) {
          const allVals = [...data.histogram.r, ...data.histogram.g, ...data.histogram.b];
          this.maxHistValue = Math.max(...allVals, 1);
        }
      },
      error: () => {
        // L'errorInterceptor a déjà signalé le problème côté UI.
        this.isLoadingBiometrics = false;
      },
    });
  }

  initCanvas() {
    if (!this.canvasRef || !this.photoUrl) return;
    const canvas = this.canvasRef.nativeElement;
    this.ctx = canvas.getContext('2d');

    this.img.crossOrigin = 'Anonymous';
    this.img.onload = () => {
      // Normaliser la taille du canvas
      canvas.width = 600;
      canvas.height = 600;
      this.offscreenCanvas.width = 600;
      this.offscreenCanvas.height = 600;

      if (this.offscreenCtx) {
        this.offscreenCtx.drawImage(this.img, 0, 0, 600, 600);
        this.originalImageData = this.offscreenCtx.getImageData(0, 0, 600, 600);
      }

      this.redrawCanvas();
    };
    this.img.src = this.photoUrl;
  }

  resetView() {
    this.zoom = 1;
    this.panX = 0;
    this.panY = 0;
    this.applyFilter('none');
  }

  applyFilter(filter: 'none' | 'chlorosis' | 'necrosis' | 'heatmap') {
    this.activeFilter = filter;
    if (!this.offscreenCtx || !this.originalImageData) return;

    const w = 600;
    const h = 600;
    const imgData = new ImageData(new Uint8ClampedArray(this.originalImageData.data), w, h);
    const data = imgData.data;

    if (filter === 'chlorosis') {
      for (let i = 0; i < data.length; i += 4) {
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];
        if (r > 80 && g > 80 && b < 120 && Math.abs(r - g) < 40) {
          data[i] = 255;
          data[i + 1] = 0;
          data[i + 2] = 255;
        } else {
          const lum = 0.3 * r + 0.59 * g + 0.11 * b;
          data[i] = lum * 0.5;
          data[i + 1] = lum * 0.8;
          data[i + 2] = lum * 0.5;
        }
      }
    } else if (filter === 'necrosis') {
      const src = this.originalImageData.data;
      const kernelX = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
      const kernelY = [-1, -2, -1, 0, 0, 0, 1, 2, 1];

      for (let y = 1; y < h - 1; y++) {
        for (let x = 1; x < w - 1; x++) {
          let gx = 0;
          let gy = 0;
          for (let ky = -1; ky <= 1; ky++) {
            for (let kx = -1; kx <= 1; kx++) {
              const pos = ((y + ky) * w + (x + kx)) * 4;
              const lum = 0.299 * src[pos] + 0.587 * src[pos + 1] + 0.114 * src[pos + 2];
              const weightX = kernelX[(ky + 1) * 3 + (kx + 1)];
              const weightY = kernelY[(ky + 1) * 3 + (kx + 1)];
              gx += lum * weightX;
              gy += lum * weightY;
            }
          }
          const mag = Math.min(255, Math.sqrt(gx * gx + gy * gy));
          const idx = (y * w + x) * 4;
          if (mag > 60) {
            data[idx] = 255;
            data[idx + 1] = 50;
            data[idx + 2] = 50;
          } else {
            const origLum = 0.299 * src[idx] + 0.587 * src[idx + 1] + 0.114 * src[idx + 2];
            data[idx] = origLum * 0.3;
            data[idx + 1] = origLum * 0.3;
            data[idx + 2] = origLum * 0.3;
          }
        }
      }
    } else if (filter === 'heatmap') {
      for (let i = 0; i < data.length; i += 4) {
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];
        const lum = 0.299 * r + 0.587 * g + 0.114 * b;

        if (lum < 50) {
          data[i] = 0; data[i + 1] = 0; data[i + 2] = 255;
        } else if (lum < 120) {
          data[i] = 0; data[i + 1] = 255; data[i + 2] = 255;
        } else if (lum < 180) {
          data[i] = 255; data[i + 1] = 255; data[i + 2] = 0;
        } else {
          data[i] = 255; data[i + 1] = 0; data[i + 2] = 0;
        }
      }
    }

    this.offscreenCtx.putImageData(imgData, 0, 0);
    this.redrawCanvas();
  }

  toggleLoupe() {
    this.loupeEnabled = !this.loupeEnabled;
    this.redrawCanvas();
  }

  redrawCanvas() {
    if (!this.ctx || !this.canvasRef) return;
    const canvas = this.canvasRef.nativeElement;
    const w = canvas.width;
    const h = canvas.height;

    this.ctx.clearRect(0, 0, w, h);
    this.ctx.save();
    this.ctx.translate(w / 2 + this.panX, h / 2 + this.panY);
    this.ctx.scale(this.zoom, this.zoom);
    this.ctx.translate(-w / 2, -h / 2);
    this.ctx.drawImage(this.offscreenCanvas, 0, 0);
    this.ctx.restore();

    if (this.loupeEnabled && !this.isDragging) {
      this.drawLoupe(this.loupeX, this.loupeY);
    }
  }

  drawLoupe(x: number, y: number) {
    if (!this.ctx || !this.canvasRef) return;
    const canvas = this.canvasRef.nativeElement;
    const loupeRadius = 80;
    const zoomFactor = 3;

    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.arc(x, y, loupeRadius, 0, Math.PI * 2, true);
    this.ctx.strokeStyle = '#10b981';
    this.ctx.lineWidth = 4;
    this.ctx.stroke();
    this.ctx.clip();

    // Calculer les coordonnées source sur l'offscreenCanvas en tenant compte du zoom et pan actuels
    const w = canvas.width;
    const h = canvas.height;
    // Position relative au centre zoomé/panné
    const relX = (x - (w / 2 + this.panX)) / this.zoom + w / 2;
    const relY = (y - (h / 2 + this.panY)) / this.zoom + h / 2;

    const srcX = relX - loupeRadius / zoomFactor;
    const srcY = relY - loupeRadius / zoomFactor;
    const srcW = (loupeRadius * 2) / zoomFactor;
    const srcH = (loupeRadius * 2) / zoomFactor;

    this.ctx.drawImage(
      this.offscreenCanvas,
      srcX, srcY, srcW, srcH,
      x - loupeRadius, y - loupeRadius, loupeRadius * 2, loupeRadius * 2
    );
    this.ctx.restore();
  }

  onWheel(event: WheelEvent) {
    event.preventDefault();
    const zoomDirection = event.deltaY < 0 ? 1.1 : 0.9;
    this.zoom = Math.min(Math.max(0.5, this.zoom * zoomDirection), 5);
    this.redrawCanvas();
  }

  onMouseDown(event: MouseEvent) {
    this.isDragging = true;
    this.startX = event.clientX;
    this.startY = event.clientY;
  }

  onMouseMove(event: MouseEvent) {
    if (!this.canvasRef) return;
    const rect = this.canvasRef.nativeElement.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;

    if (this.isDragging) {
      this.panX += event.clientX - this.startX;
      this.panY += event.clientY - this.startY;
      this.startX = event.clientX;
      this.startY = event.clientY;
      this.redrawCanvas();
    } else if (this.loupeEnabled) {
      this.loupeX = x;
      this.loupeY = y;
      this.redrawCanvas();
    }
  }

  onMouseUp() {
    this.isDragging = false;
  }
}
