import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { DiagnosticService, DiagnosticRequest } from '../../core/services/diagnostic.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';
import { AdvancedImageAnalyzerComponent } from '../../components/advanced-image-analyzer/advanced-image-analyzer.component';

@Component({
  selector: 'app-diagnostics',
  standalone: true,
  imports: [CommonModule, LucideAngularModule, FormsModule, AdvancedImageAnalyzerComponent],
  template: `
    <div class="space-y-6">
      <div class="flex justify-between items-end">
        <div>
          <h2 class="text-2xl font-extrabold text-slate-900 tracking-tight">Diagnostics Experts</h2>
          <p class="text-slate-500 font-medium">Validation et supervision des analyses Claude 3.5 Sonnet</p>
        </div>
        
        <div class="flex gap-3">
          <div class="relative">
            <lucide-icon name="search" class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"></lucide-icon>
            <input [(ngModel)]="searchQuery" type="text" placeholder="Rechercher un producteur..." class="pl-10 pr-4 py-2 bg-white border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none w-64 transition-all">
          </div>
          <select [(ngModel)]="statusFilter" class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-semibold text-slate-700 outline-none focus:ring-2 focus:ring-primary/20">
            <option value="">Tous les statuts</option>
            <option value="pending">En attente</option>
            <option value="analyzed">Analysé</option>
            <option value="validated">Validé</option>
            <option value="rejected">Rejeté</option>
          </select>
        </div>
      </div>

      <div class="grid grid-cols-12 gap-8">
        <!-- List -->
        <div class="col-span-8 space-y-4">
          <div *ngFor="let req of filteredDiagnostics" 
               (click)="selectedRequest = req"
               [class.ring-2]="selectedRequest?.id === req.id"
               [class.ring-primary]="selectedRequest?.id === req.id"
               class="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 flex items-center gap-4 hover:shadow-md transition-all cursor-pointer">
            
            <div class="w-20 h-20 bg-gray-100 rounded-xl overflow-hidden relative group">
               <img *ngIf="req.photoUrl" [src]="req.photoUrl" class="w-full h-full object-cover" (error)="onImgError($event)">
               <div class="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                 <lucide-icon name="external-link" class="text-white w-5 h-5"></lucide-icon>
               </div>
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <span class="text-xs font-bold px-2 py-0.5 rounded-full" 
                      [ngClass]="{
                        'bg-amber-100 text-amber-700': req.status === 'pending',
                        'bg-blue-100 text-blue-700': req.status === 'analyzed',
                        'bg-emerald-100 text-emerald-700': req.status === 'validated',
                        'bg-red-100 text-red-700': req.status === 'rejected'
                      }">
                  {{ req.status | uppercase }}
                </span>
                <span class="text-[10px] font-bold text-slate-400">{{ req.createdAt | date:'short' }}</span>
              </div>
              <h3 class="font-bold text-slate-900 truncate">{{ req.ownerName }}</h3>
              <p class="text-sm text-slate-500 font-medium">Parcelle: #{{ req.parcelId.split('-')[0] }}</p>
            </div>

            <div class="text-right" *ngIf="req.aiResult">
              <div class="flex items-center gap-1.5 justify-end mb-1">
                <lucide-icon name="microscope" class="w-4 h-4 text-primary"></lucide-icon>
                <span class="text-sm font-black text-primary">{{ req.aiResult.label }}</span>
              </div>
              <div class="flex items-center gap-2 justify-end">
                <div class="w-24 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                  <div class="h-full bg-primary" [style.width.%]="req.aiResult.confidence * 100"></div>
                </div>
                <span class="text-[10px] font-bold text-slate-400">{{ req.aiResult.confidence | percent }}</span>
              </div>
            </div>
          </div>
          
          <div *ngIf="filteredDiagnostics.length === 0" class="bg-white rounded-2xl p-12 text-center border-2 border-dashed border-gray-200">
            <lucide-icon name="circle-alert" class="w-12 h-12 text-slate-300 mx-auto mb-4"></lucide-icon>
            <p class="text-slate-500 font-bold">Aucune demande trouvée</p>
          </div>
        </div>

        <!-- Detail / Validation Panel -->
        <div class="col-span-4">
          <div class="sticky top-8 bg-white rounded-3xl p-6 shadow-2xl border border-gray-100 min-h-[600px] flex flex-col" *ngIf="selectedRequest; else noSelection">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-xl font-black text-slate-900">Détails de l'analyse</h3>
              <button (click)="selectedRequest = null" class="text-slate-400 hover:text-slate-600">
                <lucide-icon name="circle-x" class="w-6 h-6"></lucide-icon>
              </button>
            </div>

            <div class="rounded-2xl overflow-hidden mb-6 aspect-video bg-gray-100 shadow-inner">
               <img *ngIf="selectedRequest.photoUrl" [src]="selectedRequest.photoUrl" class="w-full h-full object-cover" (error)="onImgError($event)">
            </div>

            <div class="space-y-4 flex-1">
              <div class="grid grid-cols-2 gap-4">
                <div class="p-3 bg-gray-50 rounded-xl">
                  <div class="flex items-center gap-2 text-slate-400 mb-1">
                    <lucide-icon name="user" class="w-3 h-3"></lucide-icon>
                    <span class="text-[10px] font-black uppercase tracking-widest">Producteur</span>
                  </div>
                  <p class="text-sm font-bold text-slate-800">{{ selectedRequest.ownerName }}</p>
                </div>
                <div class="p-3 bg-gray-50 rounded-xl">
                  <div class="flex items-center gap-2 text-slate-400 mb-1">
                    <lucide-icon name="calendar" class="w-3 h-3"></lucide-icon>
                    <span class="text-[10px] font-black uppercase tracking-widest">Date</span>
                  </div>
                  <p class="text-sm font-bold text-slate-800">{{ selectedRequest.createdAt | date:'mediumDate' }}</p>
                </div>
              </div>

              <div class="p-4 bg-primary/5 border border-primary/10 rounded-2xl" *ngIf="selectedRequest.aiResult">
                <div class="flex items-center gap-2 mb-2">
                  <lucide-icon name="microscope" class="w-4 h-4 text-primary"></lucide-icon>
                  <span class="text-xs font-black text-primary uppercase tracking-widest">Diagnostic Claude 3.5</span>
                </div>
                <h4 class="text-lg font-black text-primary mb-1">{{ selectedRequest.aiResult.label }}</h4>
                <p class="text-sm text-primary/80 leading-relaxed font-medium italic">"{{ selectedRequest.aiResult.recommendations }}"</p>
              </div>

              <div class="space-y-3">
                <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest block ml-1">Commentaire de l'Expert</label>
                <textarea [(ngModel)]="adminComment" 
                          placeholder="Ajoutez vos remarques ou ajustez les conseils..." 
                          class="w-full p-4 bg-gray-50 border border-gray-200 rounded-2xl text-sm focus:ring-2 focus:ring-primary/20 outline-none transition-all min-h-[100px]"></textarea>
              </div>

              <div class="mt-6 p-4 bg-slate-900 text-white rounded-2xl flex items-center justify-between shadow-xl">
                <div class="flex items-center gap-3">
                  <lucide-icon name="microscope" class="w-6 h-6 text-primary"></lucide-icon>
                  <div>
                    <h5 class="text-sm font-black">Rayon X Agronomique</h5>
                    <p class="text-[10px] text-slate-400 font-medium">Examen WebGL des filtres et analyse biométrique foliaire</p>
                  </div>
                </div>
                <button (click)="showAnalyzer = true" class="px-4 py-2.5 bg-primary hover:bg-primary-dark text-white rounded-xl font-bold text-xs transition-all shadow-lg shadow-primary/20 flex items-center gap-1.5">
                  <lucide-icon name="zoom-in" class="w-4 h-4"></lucide-icon>
                  Ouvrir le Studio
                </button>
              </div>
            </div>

            <div class="mt-8 grid grid-cols-3 gap-3">
              <button (click)="selectedRequest = null" class="px-4 py-4 bg-gray-100 text-slate-700 rounded-2xl font-black text-xs hover:bg-gray-200 transition-all flex items-center justify-center gap-1">
                Annuler
              </button>
              <button (click)="validate(false)" class="px-4 py-4 bg-red-50 text-red-600 rounded-2xl font-black text-xs hover:bg-red-100 transition-all flex items-center justify-center gap-1">
                <lucide-icon name="circle-x" class="w-4 h-4"></lucide-icon>
                Rejeter
              </button>
              <button (click)="validate(true)" class="px-4 py-4 bg-primary text-white rounded-2xl font-black text-xs hover:bg-primary-dark shadow-lg shadow-primary/30 transition-all flex items-center justify-center gap-1">
                <lucide-icon name="circle-check" class="w-4 h-4"></lucide-icon>
                Valider
              </button>
            </div>
          </div>

          <ng-template #noSelection>
            <div class="bg-white/50 border-2 border-dashed border-gray-200 rounded-3xl p-12 text-center h-full flex flex-col items-center justify-center">
              <lucide-icon name="microscope" class="w-16 h-16 text-slate-200 mb-4"></lucide-icon>
              <p class="text-slate-400 font-black text-lg">Sélectionnez une analyse</p>
              <p class="text-slate-300 text-sm font-medium">Pour revoir les détails et valider</p>
            </div>
          </ng-template>
        </div>
      </div>

      <app-advanced-image-analyzer 
        *ngIf="showAnalyzer && selectedRequest"
        [photoUrl]="selectedRequest.photoUrl || ''"
        [diagnosticId]="selectedRequest.id"
        title="Rayon X Agronomique — {{ selectedRequest.ownerName }}"
        (close)="showAnalyzer = false">
      </app-advanced-image-analyzer>
    </div>
  `,
  styles: [`
    :host { display: block; }
  `]
})
export class DiagnosticsComponent implements OnInit {
  diagnostics: DiagnosticRequest[] = [];
  selectedRequest: DiagnosticRequest | null = null;
  adminComment: string = '';
  searchQuery = '';
  statusFilter = '';
  showAnalyzer = false;

  private diagnosticService = inject(DiagnosticService);
  private alertService = inject(AlertConfirmService);

  ngOnInit() {
    this.loadDiagnostics();
  }

  loadDiagnostics() {
    this.diagnosticService.getAll().subscribe({
      next: (data) => this.diagnostics = data,
      error: (err) => console.error('Erreur chargement diagnostics:', err)
    });
  }

  get filteredDiagnostics(): DiagnosticRequest[] {
    return this.diagnostics.filter(d => {
      const matchesSearch = !this.searchQuery || 
        d.ownerName.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        d.parcelId.toLowerCase().includes(this.searchQuery.toLowerCase());
      const matchesStatus = !this.statusFilter || d.status === this.statusFilter;
      return matchesSearch && matchesStatus;
    });
  }

  validate(approve: boolean) {
    if (!this.selectedRequest) return;
    
    const action = approve ? 'valider' : 'rejeter';
    this.alertService.confirm({
      title: `${approve ? 'Validation' : 'Rejet'} du diagnostic`,
      message: `Voulez-vous vraiment ${action} le diagnostic pour la parcelle #${this.selectedRequest.parcelId.split('-')[0]} de ${this.selectedRequest.ownerName} ?`,
      confirmText: action.toUpperCase(),
      confirmButtonColor: approve ? 'bg-primary hover:bg-primary-dark shadow-primary/20' : 'bg-red-600 hover:bg-red-700 shadow-red-600/20',
      onConfirm: () => {
        if (!this.selectedRequest) return;
        this.diagnosticService.validate(this.selectedRequest.id, approve, this.adminComment).subscribe({
          next: () => {
            this.alertService.success(`Le diagnostic a été ${approve ? 'validé' : 'rejeté'} avec succès.`);
            this.loadDiagnostics();
            this.selectedRequest = null;
            this.adminComment = '';
          },
          error: (err) => this.alertService.error('Erreur lors de la validation: ' + err.message)
        });
      }
    });
  }

  onImgError(event: Event) {
    (event.target as HTMLImageElement).src =
      'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 24 24" fill="none" stroke="%23cbd5e1" stroke-width="1.5"%3E%3Crect x="3" y="3" width="18" height="18" rx="2"/%3E%3Ccircle cx="8.5" cy="8.5" r="1.5"/%3E%3Cpath d="M21 15l-5-5L5 21"/%3E%3C/svg%3E';
  }
}
