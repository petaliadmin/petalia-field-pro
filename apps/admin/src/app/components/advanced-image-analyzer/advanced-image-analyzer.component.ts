import { Component, OnInit, Input, Output, EventEmitter, ElementRef, ViewChild, inject, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { DiagnosticService } from '../../core/services/diagnostic.service';

@Component({
  selector: 'app-advanced-image-analyzer',
  standalone: true,
  imports: [CommonModule, LucideAngularModule, FormsModule],
  template: `
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 backdrop-blur-md p-6">
      <div class="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-7xl h-[90vh] flex flex-col overflow-hidden shadow-2xl text-slate-100">
        
        <!-- Header -->
        <div class="px-8 py-5 border-b border-slate-800 flex items-center justify-between bg-slate-900/50">
          <div class="flex items-center gap-3">
            <div class="p-2.5 bg-primary/20 border border-primary/30 rounded-2xl text-primary">
              <lucide-icon name="microscope" class="w-6 h-6"></lucide-icon>
            </div>
            <div>
              <h2 class="text-xl font-black text-white tracking-tight">{{ title }}</h2>
              <p class="text-xs text-slate-400 font-medium">Rayon X Agronomique & Analyse Biométrique Foliaire</p>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <button (click)="resetView()" class="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl font-bold text-xs transition-all flex items-center gap-1.5 border border-slate-700">
              <lucide-icon name="rotate-ccw" class="w-4 h-4"></lucide-icon>
              Réinitialiser
            </button>
            <button (click)="close.emit()" class="p-2.5 bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white rounded-xl transition-all border border-slate-700">
              <lucide-icon name="x" class="w-5 h-5"></lucide-icon>
            </button>
          </div>
        </div>

        <!-- Main Workspace -->
        <div class="flex-1 grid grid-cols-12 overflow-hidden">
          
          <!-- Left Sidebar: Filters & Tools -->
          <div class="col-span-3 border-r border-slate-800 p-6 flex flex-col gap-6 bg-slate-900/30 overflow-y-auto">
            <div>
              <h3 class="text-xs font-black text-slate-400 uppercase tracking-widest mb-4 flex items-center gap-2">
                <lucide-icon name="sliders" class="w-4 h-4 text-primary"></lucide-icon>
                Filtres Agronomiques
              </h3>

              <div class="space-y-3">
                <button (click)="applyFilter('none')" 
                        [class.bg-primary]="activeFilter === 'none'"
                        [class.text-white]="activeFilter === 'none'"
                        [class.bg-slate-800]="activeFilter !== 'none'"
                        [class.text-slate-300]="activeFilter !== 'none'"
                        class="w-full p-4 rounded-2xl font-bold text-left text-sm transition-all flex items-center justify-between border border-slate-700/50 hover:border-slate-600 group">
                  <div class="flex items-center gap-3">
                    <lucide-icon name="image" class="w-5 h-5"></lucide-icon>
                    <div>
                      <div class="font-black">Image Originale</div>
                      <div class="text-[10px] opacity-70 font-medium">Vue brute du capteur mobile</div>
                    </div>
                  </div>
                  <lucide-icon *ngIf="activeFilter === 'none'" name="check-circle-2" class="w-5 h-5"></lucide-icon>
                </button>

                <button (click)="applyFilter('chlorosis')" 
                        [class.bg-amber-500]="activeFilter === 'chlorosis'"
                        [class.text-slate-950]="activeFilter === 'chlorosis'"
                        [class.bg-slate-800]="activeFilter !== 'chlorosis'"
                        [class.text-slate-300]="activeFilter !== 'chlorosis'"
                        class="w-full p-4 rounded-2xl font-bold text-left text-sm transition-all flex items-center justify-between border border-slate-700/50 hover:border-slate-600 group">
                  <div class="flex items-center gap-3">
                    <lucide-icon name="sun" class="w-5 h-5"></lucide-icon>
                    <div>
                      <div class="font-black">Filtre Chlorose</div>
                      <div class="text-[10px] opacity-70 font-medium">Amplification V/R (Jaunissement précoce)</div>
                    </div>
                  </div>
                  <lucide-icon *ngIf="activeFilter === 'chlorosis'" name="check-circle-2" class="w-5 h-5"></lucide-icon>
                </button>

                <button (click)="applyFilter('necrosis')" 
                        [class.bg-rose-500]="activeFilter === 'necrosis'"
                        [class.text-white]="activeFilter === 'necrosis'"
                        [class.bg-slate-800]="activeFilter !== 'necrosis'"
                        [class.text-slate-300]="activeFilter !== 'necrosis'"
                        class="w-full p-4 rounded-2xl font-bold text-left text-sm transition-all flex items-center justify-between border border-slate-700/50 hover:border-slate-600 group">
                  <div class="flex items-center gap-3">
                    <lucide-icon name="alert-triangle" class="w-5 h-5"></lucide-icon>
                    <div>
                      <div class="font-black">Filtre Nécrose (Sobel)</div>
                      <div class="text-[10px] opacity-70 font-medium">Détection de contours (Attaques fongiques)</div>
                    </div>
                  </div>
                  <lucide-icon *ngIf="activeFilter === 'necrosis'" name="check-circle-2" class="w-5 h-5"></lucide-icon>
                </button>

                <button (click)="applyFilter('heatmap')" 
                        [class.bg-cyan-500]="activeFilter === 'heatmap'"
                        [class.text-slate-950]="activeFilter === 'heatmap'"
                        [class.bg-slate-800]="activeFilter !== 'heatmap'"
                        [class.text-slate-300]="activeFilter !== 'heatmap'"
                        class="w-full p-4 rounded-2xl font-bold text-left text-sm transition-all flex items-center justify-between border border-slate-700/50 hover:border-slate-600 group">
                  <div class="flex items-center gap-3">
                    <lucide-icon name="flame" class="w-5 h-5"></lucide-icon>
                    <div>
                      <div class="font-black">Carte de Chaleur</div>
                      <div class="text-[10px] opacity-70 font-medium">Spectre fausse couleur (Stress hydrique)</div>
                    </div>
                  </div>
                  <lucide-icon *ngIf="activeFilter === 'heatmap'" name="check-circle-2" class="w-5 h-5"></lucide-icon>
                </button>
              </div>
            </div>

            <div>
              <h3 class="text-xs font-black text-slate-400 uppercase tracking-widest mb-4 flex items-center gap-2">
                <lucide-icon name="zoom-in" class="w-4 h-4 text-primary"></lucide-icon>
                Outils d'Examen
              </h3>

              <button (click)="toggleLoupe()" 
                      [class.bg-primary]="loupeEnabled"
                      [class.text-white]="loupeEnabled"
                      [class.bg-slate-800]="!loupeEnabled"
                      [class.text-slate-300]="!loupeEnabled"
                      class="w-full p-4 rounded-2xl font-bold text-left text-sm transition-all flex items-center justify-between border border-slate-700/50 hover:border-slate-600">
                <div class="flex items-center gap-3">
                  <lucide-icon name="search" class="w-5 h-5"></lucide-icon>
                  <div>
                    <div class="font-black">Loupe Agronomique (x4)</div>
                    <div class="text-[10px] opacity-70 font-medium">Survol interactif haute définition</div>
                  </div>
                </div>
                <div class="w-8 h-5 rounded-full p-0.5 transition-all" [class.bg-primary-dark]="loupeEnabled" [class.bg-slate-700]="!loupeEnabled">
                  <div class="w-4 h-4 rounded-full bg-white transition-all" [class.translate-x-3]="loupeEnabled"></div>
                </div>
              </button>
            </div>

            <div class="mt-auto p-4 bg-slate-800/50 border border-slate-700/50 rounded-2xl">
              <div class="flex items-center gap-2 text-xs font-bold text-slate-300 mb-1">
                <lucide-icon name="info" class="w-4 h-4 text-primary"></lucide-icon>
                Navigation Canvas
              </div>
              <p class="text-[10px] text-slate-400 leading-relaxed font-medium">
                Utilisez la molette de la souris pour zoomer/dézoomer et le cliquer-glisser pour vous déplacer dans l'image.
              </p>
            </div>
          </div>

          <!-- Center Canvas Viewport -->
          <div class="col-span-6 bg-slate-950 relative overflow-hidden flex items-center justify-center"
               (wheel)="onWheel($event)"
               (mousedown)="onMouseDown($event)"
               (mousemove)="onMouseMove($event)"
               (mouseup)="onMouseUp()"
               (mouseleave)="onMouseUp()">
            
            <canvas #canvas class="cursor-crosshair shadow-2xl"></canvas>

            <!-- Zoom Indicator Overlay -->
            <div class="absolute bottom-6 left-6 px-4 py-2 bg-slate-900/80 backdrop-blur-md border border-slate-800 rounded-xl text-xs font-black text-slate-300 flex items-center gap-2 shadow-lg">
              <lucide-icon name="zoom-in" class="w-4 h-4 text-primary"></lucide-icon>
              Zoom: {{ zoom | percent }}
            </div>

            <div *ngIf="isLoadingBiometrics" class="absolute inset-0 bg-slate-950/80 backdrop-blur-sm flex flex-col items-center justify-center gap-4">
              <div class="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
              <p class="text-sm font-bold text-slate-300">Analyse biométrique en cours par sharp...</p>
            </div>
          </div>

          <!-- Right Sidebar: Biometrics Panel -->
          <div class="col-span-3 border-l border-slate-800 p-6 flex flex-col gap-6 bg-slate-900/30 overflow-y-auto">
            <div>
              <h3 class="text-xs font-black text-slate-400 uppercase tracking-widest mb-4 flex items-center gap-2">
                <lucide-icon name="bar-chart-2" class="w-4 h-4 text-primary"></lucide-icon>
                Métriques Biométriques
              </h3>

              <div *ngIf="biometrics; else noBiometrics" class="space-y-6">
                <!-- Blur Score -->
                <div class="p-4 bg-slate-800/40 border border-slate-700/50 rounded-2xl space-y-2">
                  <div class="flex justify-between items-center text-xs">
                    <span class="font-black text-slate-300">Netteté (Blur Score)</span>
                    <span class="font-black text-primary">{{ biometrics.blurScore * 100 }}%</span>
                  </div>
                  <div class="w-full h-2 bg-slate-700 rounded-full overflow-hidden">
                    <div class="h-full bg-primary rounded-full transition-all" [style.width.%]="biometrics.blurScore * 100"></div>
                  </div>
                  <p class="text-[10px] text-slate-400 font-medium italic">
                    {{ biometrics.blurScore > 0.5 ? 'Image nette, idéale pour l\'analyse IA.' : 'Attention: Flou de bougé détecté.' }}
                  </p>
                </div>

                <!-- Ratios -->
                <div class="grid grid-cols-2 gap-4">
                  <div class="p-4 bg-amber-500/10 border border-amber-500/20 rounded-2xl text-center">
                    <div class="text-[10px] font-black text-amber-500 uppercase tracking-widest mb-1">Chlorose</div>
                    <div class="text-2xl font-black text-amber-400">{{ biometrics.chlorosisRatio | percent }}</div>
                    <div class="text-[10px] text-slate-400 font-medium mt-1">Surface jaunie</div>
                  </div>

                  <div class="p-4 bg-rose-500/10 border border-rose-500/20 rounded-2xl text-center">
                    <div class="text-[10px] font-black text-rose-500 uppercase tracking-widest mb-1">Nécrose</div>
                    <div class="text-2xl font-black text-rose-400">{{ biometrics.necrosisRatio | percent }}</div>
                    <div class="text-[10px] text-slate-400 font-medium mt-1">Taches / Brûlures</div>
                  </div>
                </div>

                <!-- RGB Histogram -->
                <div class="p-4 bg-slate-800/40 border border-slate-700/50 rounded-2xl space-y-3">
                  <div class="text-xs font-black text-slate-300">Histogramme RGB (16 bins)</div>
                  
                  <div class="space-y-2 pt-2">
                    <!-- Red Channel -->
                    <div class="flex items-end gap-0.5 h-16 bg-slate-900/50 p-2 rounded-xl border border-slate-800">
                      <div *ngFor="let val of biometrics.histogram.r" 
                           class="flex-1 bg-rose-500/80 hover:bg-rose-500 rounded-t transition-all"
                           [style.height.%]="(val / maxHistValue) * 100"></div>
                    </div>
                    <div class="text-[10px] font-bold text-rose-400 text-right">Canal Rouge (R)</div>

                    <!-- Green Channel -->
                    <div class="flex items-end gap-0.5 h-16 bg-slate-900/50 p-2 rounded-xl border border-slate-800">
                      <div *ngFor="let val of biometrics.histogram.g" 
                           class="flex-1 bg-emerald-500/80 hover:bg-emerald-500 rounded-t transition-all"
                           [style.height.%]="(val / maxHistValue) * 100"></div>
                    </div>
                    <div class="text-[10px] font-bold text-emerald-400 text-right">Canal Vert (G)</div>

                    <!-- Blue Channel -->
                    <div class="flex items-end gap-0.5 h-16 bg-slate-900/50 p-2 rounded-xl border border-slate-800">
                      <div *ngFor="let val of biometrics.histogram.b" 
                           class="flex-1 bg-cyan-500/80 hover:bg-cyan-500 rounded-t transition-all"
                           [style.height.%]="(val / maxHistValue) * 100"></div>
                    </div>
                    <div class="text-[10px] font-bold text-cyan-400 text-right">Canal Bleu (B)</div>
                  </div>
                </div>
              </div>

              <ng-template #noBiometrics>
                <div *ngIf="!isLoadingBiometrics" class="p-8 bg-slate-800/20 border border-slate-700/40 rounded-2xl text-center space-y-3">
                  <lucide-icon name="alert-circle" class="w-8 h-8 text-slate-500 mx-auto"></lucide-icon>
                  <p class="text-xs text-slate-400 font-bold">Données biométriques indisponibles</p>
                </div>
              </ng-template>
            </div>

            <div class="mt-auto p-4 bg-primary/10 border border-primary/20 rounded-2xl flex items-center gap-3">
              <lucide-icon name="cpu" class="w-6 h-6 text-primary flex-shrink-0"></lucide-icon>
              <p class="text-[10px] text-primary-light font-bold leading-relaxed">
                Les métriques biométriques sont automatiquement injectées dans le prompt de Claude 3.5 Sonnet.
              </p>
            </div>
          </div>

        </div>

      </div>
    </div>
  `,
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
