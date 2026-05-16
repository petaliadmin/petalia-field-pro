import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { ParcelService, Parcel } from '../../core/services/parcel.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-parcels',
  standalone: true,
  imports: [CommonModule, FormsModule, LucideAngularModule],
  template: `
    <div class="space-y-6">
      <div class="flex justify-between items-center">
        <div>
          <h2 class="text-2xl font-black text-slate-900 tracking-tight">Parcelles</h2>
          <p class="text-slate-500 font-medium">{{ parcels.length }} parcelles enregistrées</p>
        </div>

        <button (click)="openCreateModal()" class="flex items-center gap-2 px-6 py-3 bg-primary text-white rounded-2xl font-black text-sm shadow-xl shadow-primary/20 hover:bg-primary-dark transition-all">
          <lucide-icon name="plus" class="w-5 h-5"></lucide-icon>
          Nouvelle Parcelle
        </button>
      </div>

      <!-- Filters & Search -->
      <div class="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex items-center justify-between gap-4">
        <div class="flex-1 relative">
          <lucide-icon name="search" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"></lucide-icon>
          <input [(ngModel)]="searchQuery" type="text" placeholder="Rechercher par producteur, ID ou région..."
                 class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-transparent rounded-xl text-sm focus:bg-white focus:border-primary/20 outline-none transition-all">
        </div>
        <select [(ngModel)]="statusFilter"
                class="px-4 py-3 bg-gray-50 text-slate-600 rounded-xl text-sm font-bold border-none outline-none focus:ring-2 focus:ring-primary/20">
          <option value="">Tous les statuts</option>
          <option value="healthy">Sain</option>
          <option value="water_stress">Stress Hydrique</option>
          <option value="infection">Infection Détectée</option>
          <option value="unknown">Inconnu</option>
        </select>
      </div>

      <!-- Status Summary -->
      <div *ngIf="!loading && parcels.length > 0" class="grid grid-cols-4 gap-4">
        <div class="bg-white px-5 py-4 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
          <span class="w-3 h-3 bg-emerald-500 rounded-full shrink-0"></span>
          <div>
            <p class="text-xs font-black text-slate-400 uppercase tracking-widest">Sains</p>
            <p class="text-xl font-black text-slate-900">{{ countByStatus('healthy') }}</p>
          </div>
        </div>
        <div class="bg-white px-5 py-4 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
          <span class="w-3 h-3 bg-amber-500 rounded-full shrink-0"></span>
          <div>
            <p class="text-xs font-black text-slate-400 uppercase tracking-widest">Stress Hydrique</p>
            <p class="text-xl font-black text-slate-900">{{ countByStatus('water_stress') }}</p>
          </div>
        </div>
        <div class="bg-white px-5 py-4 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
          <span class="w-3 h-3 bg-red-500 rounded-full shrink-0"></span>
          <div>
            <p class="text-xs font-black text-slate-400 uppercase tracking-widest">Infection</p>
            <p class="text-xl font-black text-slate-900">{{ countByStatus('infection') }}</p>
          </div>
        </div>
        <div class="bg-white px-5 py-4 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
          <span class="w-3 h-3 bg-slate-300 rounded-full shrink-0"></span>
          <div>
            <p class="text-xs font-black text-slate-400 uppercase tracking-widest">Inconnus</p>
            <p class="text-xl font-black text-slate-900">{{ countByStatus('unknown') }}</p>
          </div>
        </div>
      </div>

      <!-- Loading -->
      <div *ngIf="loading" class="grid grid-cols-3 gap-4">
        <div *ngFor="let i of [1,2,3,4,5,6]" class="bg-white p-5 rounded-2xl border border-gray-100 animate-pulse">
          <div class="h-4 bg-slate-100 rounded w-3/4 mb-3"></div>
          <div class="h-3 bg-slate-100 rounded w-1/2 mb-2"></div>
          <div class="h-3 bg-slate-100 rounded w-2/3"></div>
        </div>
      </div>

      <!-- Empty State -->
      <div *ngIf="!loading && filteredParcels.length === 0"
           class="bg-white rounded-2xl p-12 text-center border-2 border-dashed border-gray-200">
        <lucide-icon name="map-pin" class="w-12 h-12 text-slate-300 mx-auto mb-4"></lucide-icon>
        <p class="text-slate-500 font-bold">Aucune parcelle trouvée</p>
      </div>

      <!-- Parcels Table -->
      <div *ngIf="!loading" class="bg-white rounded-[32px] border border-gray-100 shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-gray-50/75 border-b border-gray-100 text-[11px] font-black text-slate-400 uppercase tracking-wider">
                <th class="py-4 px-6">Statut</th>
                <th class="py-4 px-6">Producteur</th>
                <th class="py-4 px-6">Contact</th>
                <th class="py-4 px-6">Localisation & GPS</th>
                <th class="py-4 px-6">Culture & Superficie</th>
                <th class="py-4 px-6">Création</th>
                <th class="py-4 px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 text-sm font-medium text-slate-600">
              <tr *ngFor="let parcel of filteredParcels" class="hover:bg-primary/5 transition-colors group">
                <td class="py-4 px-6">
                  <div class="flex items-center gap-2">
                    <span class="w-2.5 h-2.5 rounded-full shrink-0"
                          [ngClass]="{
                            'bg-emerald-500': parcel.status === 'healthy',
                            'bg-amber-500': parcel.status === 'water_stress',
                            'bg-red-500': parcel.status === 'infection',
                            'bg-slate-300': parcel.status === 'unknown'
                          }"></span>
                    <span class="text-xs font-black px-2.5 py-1 rounded-lg"
                          [ngClass]="{
                            'bg-emerald-100 text-emerald-700': parcel.status === 'healthy',
                            'bg-amber-100 text-amber-700': parcel.status === 'water_stress',
                            'bg-red-100 text-red-700': parcel.status === 'infection',
                            'bg-slate-100 text-slate-600': parcel.status === 'unknown'
                          }">
                      {{ statusLabel(parcel.status) }}
                    </span>
                  </div>
                </td>

                <td class="py-4 px-6">
                  <div class="font-black text-slate-900 text-base group-hover:text-primary transition-colors">{{ parcel.ownerName }}</div>
                </td>

                <td class="py-4 px-6">
                  <div *ngIf="parcel.ownerPhone" class="flex items-center gap-1.5 text-slate-700">
                    <lucide-icon name="phone" class="w-3.5 h-3.5 text-primary"></lucide-icon>
                    <span class="font-bold text-xs">{{ parcel.ownerPhone }}</span>
                  </div>
                  <span *ngIf="!parcel.ownerPhone" class="text-xs text-slate-300 italic">Non renseigné</span>
                </td>

                <td class="py-4 px-6">
                  <div *ngIf="parcel.location?.region" class="flex items-center gap-1.5 text-slate-800 font-bold mb-1">
                    <lucide-icon name="map-pin" class="w-3.5 h-3.5 text-primary"></lucide-icon>
                    <span class="text-xs">{{ parcel.location!.region }}</span>
                  </div>
                  <div *ngIf="parcel.location?.lat && parcel.location?.lng" class="flex items-center gap-1.5 text-slate-400 text-[11px] font-mono">
                    <lucide-icon name="compass" class="w-3.5 h-3.5 text-blue-500"></lucide-icon>
                    <span>{{ parcel.location!.lat }}°N, {{ parcel.location!.lng }}°E</span>
                  </div>
                </td>

                <td class="py-4 px-6">
                  <div *ngIf="parcel.cropType" class="flex items-center gap-1.5 text-emerald-700 font-black mb-1">
                    <lucide-icon name="leaf" class="w-3.5 h-3.5 text-emerald-500"></lucide-icon>
                    <span class="text-xs">{{ parcel.cropType }}</span>
                  </div>
                  <div *ngIf="parcel.area" class="flex items-center gap-1.5 text-slate-500 text-xs font-bold">
                    <lucide-icon name="layers" class="w-3.5 h-3.5 text-amber-500"></lucide-icon>
                    <span>{{ parcel.area }} ha</span>
                  </div>
                </td>

                <td class="py-4 px-6">
                  <div class="flex items-center gap-1.5 text-slate-500 text-xs font-bold">
                    <lucide-icon name="calendar" class="w-3.5 h-3.5 text-slate-400"></lucide-icon>
                    <span>{{ parcel.createdAt | date:'dd/MM/yyyy HH:mm' }}</span>
                  </div>
                </td>

                <td class="py-4 px-6 text-right">
                  <div class="flex items-center justify-end gap-1.5">
                    <button (click)="openPassport(parcel.id)" title="Passeport Phytosanitaire" class="p-2 bg-primary/10 text-primary hover:bg-primary hover:text-white rounded-xl transition-all flex items-center justify-center">
                      <lucide-icon name="file-text" class="w-4 h-4"></lucide-icon>
                    </button>
                    <button (click)="openDetailsModal(parcel)" title="Détails" class="p-2 bg-gray-50 text-slate-700 hover:bg-gray-100 rounded-xl transition-all flex items-center justify-center">
                      <lucide-icon name="eye" class="w-4 h-4"></lucide-icon>
                    </button>
                    <button (click)="openEditModal(parcel)" title="Modifier" class="p-2 bg-gray-50 text-slate-700 hover:bg-gray-100 rounded-xl transition-all flex items-center justify-center">
                      <lucide-icon name="edit" class="w-4 h-4"></lucide-icon>
                    </button>
                    <button (click)="openDeleteModal(parcel)" title="Supprimer" class="p-2 bg-red-50 text-red-600 hover:bg-red-100 rounded-xl transition-all flex items-center justify-center">
                      <lucide-icon name="trash-2" class="w-4 h-4"></lucide-icon>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Create/Edit Modal -->
      <div *ngIf="showParcelModal" class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in">
        <div class="bg-white rounded-[32px] p-8 max-w-lg w-full shadow-2xl border border-gray-100 relative overflow-hidden max-h-[90vh] flex flex-col">
          <div class="flex items-center justify-between mb-6 shrink-0">
            <h3 class="text-xl font-black text-slate-900">{{ isEditing ? 'Modifier Parcelle' : 'Nouvelle Parcelle' }}</h3>
            <button (click)="closeParcelModal()" class="p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-50 transition-all">
              <lucide-icon name="x" class="w-6 h-6"></lucide-icon>
            </button>
          </div>

          <div class="space-y-4 overflow-y-auto flex-1 pr-2 mb-6">
            <div>
              <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Producteur (Nom complet) *</label>
              <input [(ngModel)]="currentParcel.ownerName" type="text" placeholder="Ex: Amadou Bah" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
            </div>

            <div>
              <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Téléphone Producteur</label>
              <input [(ngModel)]="currentParcel.ownerPhone" type="text" placeholder="Ex: +221771234567" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Type de culture *</label>
                <input [(ngModel)]="currentParcel.cropType" type="text" placeholder="Ex: Riz, Maïs, Tomate" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
              </div>

              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Superficie (ha) *</label>
                <input [(ngModel)]="currentParcel.area" type="number" placeholder="Ex: 2.5" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Région / Localité</label>
                <input [(ngModel)]="regionInput" type="text" placeholder="Ex: Saint-Louis" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
              </div>

              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Statut Santé *</label>
                <select [(ngModel)]="currentParcel.status" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
                  <option value="healthy">Sain</option>
                  <option value="water_stress">Stress Hydrique</option>
                  <option value="infection">Infection Détectée</option>
                  <option value="unknown">Inconnu</option>
                </select>
              </div>
            </div>
          </div>

          <div class="flex gap-4 shrink-0">
            <button (click)="closeParcelModal()" class="flex-1 py-4 bg-gray-100 text-slate-700 rounded-2xl font-black text-sm hover:bg-gray-200 transition-all">
              ANNULER
            </button>
            <button (click)="saveParcel()" class="flex-1 py-4 bg-primary text-white rounded-2xl font-black text-sm shadow-xl shadow-primary/20 hover:bg-primary-dark transition-all flex items-center justify-center gap-2">
              <lucide-icon name="check" class="w-5 h-5"></lucide-icon>
              ENREGISTRER
            </button>
          </div>
        </div>
      </div>

      <!-- Details Modal -->
      <div *ngIf="selectedParcelDetails" class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in">
        <div class="bg-white rounded-[32px] p-8 max-w-lg w-full shadow-2xl border border-gray-100 relative overflow-hidden max-h-[90vh] flex flex-col">
          <div class="flex items-center justify-between mb-6 shrink-0">
            <div>
              <h3 class="text-xl font-black text-slate-900">Détails de la Parcelle</h3>
              <p class="text-xs font-bold text-slate-400 uppercase tracking-widest">ID: #{{ selectedParcelDetails.id }}</p>
            </div>
            <button (click)="selectedParcelDetails = null" class="p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-50 transition-all">
              <lucide-icon name="x" class="w-6 h-6"></lucide-icon>
            </button>
          </div>

          <div class="space-y-6 overflow-y-auto flex-1 pr-2 mb-8">
            <div class="p-4 bg-gray-50 rounded-2xl flex items-center justify-between">
              <div>
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Producteur</span>
                <span class="text-base font-black text-slate-900">{{ selectedParcelDetails.ownerName }}</span>
              </div>
              <div *ngIf="selectedParcelDetails.ownerPhone" class="text-right">
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Téléphone</span>
                <span class="text-sm font-bold text-primary">{{ selectedParcelDetails.ownerPhone }}</span>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="p-4 bg-gray-50 rounded-2xl">
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Culture</span>
                <span class="text-sm font-black text-slate-800">{{ selectedParcelDetails.cropType || 'Non spécifié' }}</span>
              </div>
              <div class="p-4 bg-gray-50 rounded-2xl">
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Superficie</span>
                <span class="text-sm font-black text-slate-800">{{ selectedParcelDetails.area ? selectedParcelDetails.area + ' ha' : 'Non spécifiée' }}</span>
              </div>
              <div class="p-4 bg-gray-50 rounded-2xl">
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Localité / Région</span>
                <span class="text-sm font-black text-slate-800">{{ selectedParcelDetails.location?.region || 'Non spécifiée' }}</span>
              </div>
              <div class="p-4 bg-gray-50 rounded-2xl">
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Statut</span>
                <span class="text-xs font-black px-2 py-1 rounded-lg inline-block mt-1"
                      [ngClass]="{
                        'bg-emerald-100 text-emerald-700': selectedParcelDetails.status === 'healthy',
                        'bg-amber-100 text-amber-700': selectedParcelDetails.status === 'water_stress',
                        'bg-red-100 text-red-700': selectedParcelDetails.status === 'infection',
                        'bg-slate-200 text-slate-700': selectedParcelDetails.status === 'unknown'
                      }">
                  {{ statusLabel(selectedParcelDetails.status) }}
                </span>
              </div>
            </div>

            <div class="p-4 bg-primary/5 rounded-2xl border border-primary/10 flex items-center justify-between">
              <span class="text-xs font-bold text-primary">Date de création</span>
              <span class="text-xs font-black text-primary">{{ selectedParcelDetails.createdAt | date:'medium' }}</span>
            </div>
          </div>

          <button (click)="selectedParcelDetails = null" class="w-full py-4 bg-gray-100 text-slate-700 rounded-2xl font-black text-sm hover:bg-gray-200 transition-all shrink-0">
            ANNULER
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`:host { display: block; }`]
})
export class ParcelsComponent implements OnInit {
  parcels: Parcel[] = [];
  loading = true;
  searchQuery = '';
  statusFilter = '';

  showParcelModal = false;
  isEditing = false;
  currentParcel: Partial<Parcel> = {
    ownerName: '',
    ownerPhone: '',
    cropType: '',
    area: 1,
    status: 'healthy',
  };
  regionInput = '';

  selectedParcelDetails: Parcel | null = null;

  private parcelService = inject(ParcelService);
  private alertService = inject(AlertConfirmService);

  ngOnInit() {
    this.loadParcels();
  }

  loadParcels() {
    this.loading = true;
    this.parcelService.getAll().subscribe({
      next: (data) => { this.parcels = data; this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  get filteredParcels(): Parcel[] {
    return this.parcels.filter(p => {
      const matchesSearch = !this.searchQuery ||
        p.ownerName.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        p.id.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        (p.location?.region ?? '').toLowerCase().includes(this.searchQuery.toLowerCase());
      const matchesStatus = !this.statusFilter || p.status === this.statusFilter;
      return matchesSearch && matchesStatus;
    });
  }

  countByStatus(status: Parcel['status']): number {
    return this.parcels.filter(p => p.status === status).length;
  }

  statusLabel(status: Parcel['status']): string {
    const labels: Record<Parcel['status'], string> = {
      healthy: 'Sain',
      water_stress: 'Stress Hydrique',
      infection: 'Infection',
      unknown: 'Inconnu'
    };
    return labels[status];
  }

  openPassport(id: string) {
    window.open(`${environment.apiUrl}/parcels/passport/` + id, '_blank');
  }

  openCreateModal() {
    this.isEditing = false;
    this.currentParcel = { ownerName: '', ownerPhone: '', cropType: '', area: 1, status: 'healthy' };
    this.regionInput = '';
    this.showParcelModal = true;
  }

  openEditModal(parcel: Parcel) {
    this.isEditing = true;
    this.currentParcel = { ...parcel };
    this.regionInput = parcel.location?.region || '';
    this.showParcelModal = true;
  }

  closeParcelModal() {
    this.showParcelModal = false;
  }

  saveParcel() {
    if (!this.currentParcel.ownerName || !this.currentParcel.cropType || !this.currentParcel.area) {
      this.alertService.warning('Veuillez remplir les champs obligatoires (Producteur, Culture et Superficie)');
      return;
    }

    const payload: Partial<Parcel> = {
      ...this.currentParcel,
      location: { lat: 16.033, lng: -16.483, region: this.regionInput || 'Sénégal' }
    };

    if (this.isEditing && this.currentParcel.id) {
      this.parcelService.update(this.currentParcel.id, payload).subscribe({
        next: () => {
          this.alertService.success('Parcelle modifiée avec succès');
          this.loadParcels();
          this.closeParcelModal();
        },
        error: (err) => this.alertService.error('Erreur lors de la modification : ' + err.message)
      });
    } else {
      this.parcelService.create(payload).subscribe({
        next: () => {
          this.alertService.success('Parcelle créée avec succès');
          this.loadParcels();
          this.closeParcelModal();
        },
        error: (err) => this.alertService.error('Erreur lors de la création : ' + err.message)
      });
    }
  }

  openDetailsModal(parcel: Parcel) {
    this.selectedParcelDetails = parcel;
  }

  openDeleteModal(parcel: Parcel) {
    this.alertService.confirm({
      title: 'Supprimer la parcelle ?',
      message: `Cette action est définitive et supprimera toutes les données agronomiques associées pour ${parcel.ownerName}.`,
      confirmText: 'SUPPRIMER',
      confirmButtonColor: 'bg-red-600 hover:bg-red-700 shadow-red-600/20',
      onConfirm: () => {
        this.parcelService.delete(parcel.id).subscribe({
          next: () => {
            this.alertService.success('Parcelle supprimée avec succès');
            this.loadParcels();
          },
          error: (err) => this.alertService.error('Erreur lors de la suppression : ' + err.message)
        });
      }
    });
  }
}
