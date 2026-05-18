import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { ExpertRequestsService, ExpertRequestItem } from '../../core/services/expert-requests.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';

@Component({
  selector: 'app-expert-requests',
  standalone: true,
  imports: [CommonModule, LucideAngularModule, FormsModule],
  template: `
    <div class="space-y-6 animate-fade-in">
      <div class="flex justify-between items-end">
        <div>
          <h2 class="text-2xl font-extrabold text-slate-900 tracking-tight">Demandes d'Avis Experts</h2>
          <p class="text-slate-500 font-medium">Supervision et réponse aux sollicitations agronomiques des producteurs</p>
        </div>
        
        <div class="flex gap-3">
          <div class="relative">
            <lucide-icon name="search" class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"></lucide-icon>
            <input [(ngModel)]="searchQuery" type="text" placeholder="Rechercher un producteur..." class="pl-10 pr-4 py-2 bg-white border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none w-64 transition-all">
          </div>
          <select [(ngModel)]="statusFilter" class="px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-semibold text-slate-700 outline-none focus:ring-2 focus:ring-primary/20">
            <option value="">Tous les statuts</option>
            <option value="pending">En attente</option>
            <option value="paid">Payé</option>
            <option value="completed">Complété</option>
            <option value="cancelled">Annulé</option>
          </select>
        </div>
      </div>

      <div class="grid grid-cols-12 gap-8">
        <!-- List -->
        <div class="col-span-8 space-y-4">
          <div *ngFor="let req of filteredRequests" 
               (click)="selectRequest(req)"
               [class.ring-2]="selectedRequest?.id === req.id"
               [class.ring-primary]="selectedRequest?.id === req.id"
               class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100 flex items-center gap-5 hover:shadow-md transition-all cursor-pointer">
            
            <div class="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center text-primary shrink-0 shadow-inner">
               <lucide-icon name="message-square-text" class="w-8 h-8"></lucide-icon>
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1.5">
                <span class="text-xs font-bold px-2.5 py-0.5 rounded-full" 
                      [ngClass]="{
                        'bg-amber-100 text-amber-700': req.status === 'pending',
                        'bg-blue-100 text-blue-700': req.status === 'paid',
                        'bg-emerald-100 text-emerald-700': req.status === 'completed',
                        'bg-red-100 text-red-700': req.status === 'cancelled'
                      }">
                  {{ req.status | uppercase }}
                </span>
                <span class="text-[11px] font-bold text-slate-400">{{ req.createdAt | date:'medium' }}</span>
              </div>
              <h3 class="font-bold text-slate-900 text-base truncate mb-0.5">{{ req.parcel?.owner || 'Producteur Inconnu' }}</h3>
              <p class="text-xs text-slate-500 font-medium">Parcelle: {{ req.parcel?.name }} · Village: {{ req.parcel?.village }}</p>
            </div>

            <div class="text-right shrink-0">
              <div class="flex items-center gap-1.5 justify-end mb-1">
                <lucide-icon name="user-check" class="w-4 h-4 text-primary"></lucide-icon>
                <span class="text-xs font-black text-primary">{{ req.expert?.name }}</span>
              </div>
              <span class="text-[10px] font-bold text-slate-400 block">{{ req.expert?.specialization }}</span>
            </div>
          </div>
          
          <div *ngIf="filteredRequests.length === 0" class="bg-white rounded-2xl p-12 text-center border-2 border-dashed border-gray-200">
            <lucide-icon name="circle-alert" class="w-12 h-12 text-slate-300 mx-auto mb-4"></lucide-icon>
            <p class="text-slate-500 font-bold">Aucune demande d'avis trouvée</p>
          </div>
        </div>

        <!-- Detail / Response Panel -->
        <div class="col-span-4">
          <div class="sticky top-8 bg-white rounded-3xl p-6 shadow-2xl border border-gray-100 min-h-[550px] flex flex-col" *ngIf="selectedRequest; else noSelection">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-xl font-black text-slate-900">Répondre à la demande</h3>
              <button (click)="selectedRequest = null" class="text-slate-400 hover:text-slate-600">
                <lucide-icon name="circle-x" class="w-6 h-6"></lucide-icon>
              </button>
            </div>

            <div class="space-y-4 flex-1">
              <div class="grid grid-cols-2 gap-4">
                <div class="p-3.5 bg-gray-50 rounded-2xl border border-gray-100">
                  <div class="flex items-center gap-2 text-slate-400 mb-1">
                    <lucide-icon name="user" class="w-3.5 h-3.5"></lucide-icon>
                    <span class="text-[10px] font-black uppercase tracking-widest">Producteur</span>
                  </div>
                  <p class="text-sm font-bold text-slate-800">{{ selectedRequest.parcel?.owner }}</p>
                  <p class="text-xs text-slate-500 font-medium mt-0.5">{{ selectedRequest.parcel?.phone }}</p>
                </div>
                <div class="p-3.5 bg-gray-50 rounded-2xl border border-gray-100">
                  <div class="flex items-center gap-2 text-slate-400 mb-1">
                    <lucide-icon name="map-pin" class="w-3.5 h-3.5"></lucide-icon>
                    <span class="text-[10px] font-black uppercase tracking-widest">Parcelle</span>
                  </div>
                  <p class="text-sm font-bold text-slate-800">{{ selectedRequest.parcel?.name }}</p>
                  <p class="text-xs text-slate-500 font-medium mt-0.5">{{ selectedRequest.parcel?.village }}</p>
                </div>
              </div>

              <div class="p-4 bg-primary/5 border border-primary/10 rounded-2xl">
                <div class="flex items-center gap-2 mb-1">
                  <lucide-icon name="user-check" class="w-4 h-4 text-primary"></lucide-icon>
                  <span class="text-xs font-black text-primary uppercase tracking-widest">Expert Sollicité</span>
                </div>
                <h4 class="text-base font-black text-primary">{{ selectedRequest.expert?.name }}</h4>
                <p class="text-xs text-primary/80 font-medium">{{ selectedRequest.expert?.specialization }}</p>
              </div>

              <!-- Billing trail : montant débité côté wallet du technicien -->
              <div *ngIf="selectedRequest.feeAmount" class="p-3 bg-amber-50 border border-amber-100 rounded-2xl flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <lucide-icon name="coins" class="w-4 h-4 text-amber-600" aria-hidden="true"></lucide-icon>
                  <span class="text-[10px] font-black text-amber-700 uppercase tracking-widest">Débit Wallet</span>
                </div>
                <span class="text-sm font-black text-amber-700">{{ selectedRequest.feeAmount }} XOF</span>
              </div>
              <p *ngIf="selectedRequest.status === 'cancelled' && selectedRequest.feeAmount" class="text-[11px] font-bold text-emerald-700 px-1">
                ✓ {{ selectedRequest.feeAmount }} XOF remboursés au technicien (annulation)
              </p>

              <div *ngIf="selectedRequest.context" class="p-3 bg-slate-50 border border-slate-100 rounded-2xl">
                <div class="flex items-center gap-2 mb-1 text-slate-500">
                  <lucide-icon name="file-text" class="w-3.5 h-3.5" aria-hidden="true"></lucide-icon>
                  <span class="text-[10px] font-black uppercase tracking-widest">Contexte producteur</span>
                </div>
                <p class="text-xs text-slate-700 font-medium leading-relaxed">{{ selectedRequest.context }}</p>
              </div>

              <div class="space-y-2 pt-2">
                <label class="text-xs font-black text-slate-700 uppercase tracking-wider block ml-1">Avis & Recommandations</label>
                <textarea [(ngModel)]="expertAdvice" 
                          placeholder="Rédigez les recommandations agronomiques détaillées pour le producteur..." 
                          class="w-full p-4 bg-gray-50 border border-gray-200 rounded-2xl text-sm font-medium text-slate-900 focus:bg-white focus:ring-2 focus:ring-primary/20 outline-none transition-all min-h-[160px]"></textarea>
              </div>
            </div>

            <div class="mt-8 grid grid-cols-2 gap-4">
              <button (click)="respond('cancelled')" class="py-4 bg-red-50 text-red-600 rounded-2xl font-black text-xs hover:bg-red-100 transition-all flex items-center justify-center gap-2">
                <lucide-icon name="circle-x" class="w-4 h-4"></lucide-icon>
                ANNULER DEMANDE
              </button>
              <button (click)="respond('completed')" class="py-4 bg-primary text-white rounded-2xl font-black text-xs hover:bg-primary-dark shadow-xl shadow-primary/20 transition-all flex items-center justify-center gap-2">
                <lucide-icon name="send" class="w-4 h-4"></lucide-icon>
                ENVOYER AVIS
              </button>
            </div>
          </div>

          <ng-template #noSelection>
            <div class="bg-white/50 border-2 border-dashed border-gray-200 rounded-3xl p-12 text-center h-full flex flex-col items-center justify-center">
              <lucide-icon name="message-square-text" class="w-16 h-16 text-slate-200 mb-4"></lucide-icon>
              <p class="text-slate-400 font-black text-lg">Sélectionnez une demande</p>
              <p class="text-slate-300 text-sm font-medium">Pour formuler et envoyer l'avis expert</p>
            </div>
          </ng-template>
        </div>
      </div>
    </div>
  `,
  styles: [`
    :host { display: block; }
  `]
})
export class ExpertRequestsComponent implements OnInit {
  requests: ExpertRequestItem[] = [];
  selectedRequest: ExpertRequestItem | null = null;
  expertAdvice: string = '';
  searchQuery = '';
  statusFilter = '';

  private requestsService = inject(ExpertRequestsService);
  private alertService = inject(AlertConfirmService);

  ngOnInit() {
    this.loadRequests();
  }

  loadRequests() {
    this.requestsService.getAllRequests().subscribe({
      next: (data) => (this.requests = data),
      error: () => (this.requests = []),
    });
  }

  selectRequest(req: ExpertRequestItem) {
    this.selectedRequest = req;
    this.expertAdvice = req.expertAdvice ?? '';
  }

  get filteredRequests(): ExpertRequestItem[] {
    return this.requests.filter(r => {
      const matchesSearch = !this.searchQuery || 
        (r.parcel?.owner || '').toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        (r.parcel?.name || '').toLowerCase().includes(this.searchQuery.toLowerCase());
      const matchesStatus = !this.statusFilter || r.status === this.statusFilter;
      return matchesSearch && matchesStatus;
    });
  }

  respond(status: 'completed' | 'cancelled') {
    if (!this.selectedRequest) return;
    
    const action = status === 'completed' ? 'envoyer cet avis expert' : 'annuler cette demande';
    this.alertService.confirm({
      title: `${status === 'completed' ? 'Envoi' : 'Annulation'} de l'avis expert`,
      message: `Voulez-vous vraiment ${action} pour la parcelle ${this.selectedRequest.parcel?.name} de ${this.selectedRequest.parcel?.owner} ?`,
      confirmText: status === 'completed' ? 'ENVOYER' : 'ANNULER',
      confirmButtonColor: status === 'completed' ? 'bg-primary hover:bg-primary-dark shadow-primary/20' : 'bg-red-600 hover:bg-red-700 shadow-red-600/20',
      onConfirm: () => {
        if (!this.selectedRequest) return;
        this.requestsService.respond(this.selectedRequest.id, this.expertAdvice, status).subscribe({
          next: (updated) => {
            const refundNote =
              status === 'cancelled' && updated.feeAmount
                ? ` ${updated.feeAmount} XOF ont été remboursés au technicien.`
                : '';
            this.alertService.success(
              `L'avis expert a été ${status === 'completed' ? 'envoyé' : 'annulé'} avec succès.${refundNote}`,
            );
            this.loadRequests();
            this.selectedRequest = null;
            this.expertAdvice = '';
          },
          error: () => {},
        });
      }
    });
  }
}
