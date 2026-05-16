import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { ParcelService, Parcel } from '../../core/services/parcel.service';

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

        <div class="flex gap-2">
          <div class="relative">
            <lucide-icon name="search" class="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"></lucide-icon>
            <input [(ngModel)]="searchQuery" type="text" placeholder="Rechercher..."
                   class="pl-10 pr-4 py-2 bg-white border border-gray-200 rounded-xl text-sm outline-none focus:ring-2 focus:ring-primary/20 w-64 transition-all">
          </div>
          <select [(ngModel)]="statusFilter"
                  class="px-4 py-2 bg-white border border-gray-200 rounded-xl text-sm text-slate-700 outline-none focus:ring-2 focus:ring-primary/20">
            <option value="">Tous les statuts</option>
            <option value="healthy">Sain</option>
            <option value="water_stress">Stress Hydrique</option>
            <option value="infection">Infection Détectée</option>
            <option value="unknown">Inconnu</option>
          </select>
        </div>
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

      <!-- Parcels Grid -->
      <div *ngIf="!loading" class="grid grid-cols-3 gap-4">
        <div *ngFor="let parcel of filteredParcels"
             class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm hover:shadow-md transition-all">
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full shrink-0"
                    [ngClass]="{
                      'bg-emerald-500': parcel.status === 'healthy',
                      'bg-amber-500': parcel.status === 'water_stress',
                      'bg-red-500': parcel.status === 'infection',
                      'bg-slate-300': parcel.status === 'unknown'
                    }"></span>
              <span class="text-xs font-black px-2 py-0.5 rounded-full"
                    [ngClass]="{
                      'bg-emerald-100 text-emerald-700': parcel.status === 'healthy',
                      'bg-amber-100 text-amber-700': parcel.status === 'water_stress',
                      'bg-red-100 text-red-700': parcel.status === 'infection',
                      'bg-slate-100 text-slate-600': parcel.status === 'unknown'
                    }">
                {{ statusLabel(parcel.status) }}
              </span>
            </div>
            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">
              #{{ parcel.id | slice:0:8 }}
            </span>
          </div>

          <h3 class="font-black text-slate-900 mb-1">{{ parcel.ownerName }}</h3>

          <div class="space-y-1.5 mt-3">
            <div *ngIf="parcel.location?.region" class="flex items-center gap-2 text-slate-500">
              <lucide-icon name="map-pin" class="w-3.5 h-3.5 shrink-0"></lucide-icon>
              <span class="text-xs font-medium">{{ parcel.location!.region }}</span>
            </div>
            <div *ngIf="parcel.area" class="flex items-center gap-2 text-slate-500">
              <lucide-icon name="layers" class="w-3.5 h-3.5 shrink-0"></lucide-icon>
              <span class="text-xs font-medium">{{ parcel.area }} ha</span>
            </div>
            <div *ngIf="parcel.cropType" class="flex items-center gap-2 text-slate-500">
              <lucide-icon name="leaf" class="w-3.5 h-3.5 shrink-0"></lucide-icon>
              <span class="text-xs font-medium">{{ parcel.cropType }}</span>
            </div>
            <div class="flex items-center gap-2 text-slate-400">
              <lucide-icon name="calendar" class="w-3.5 h-3.5 shrink-0"></lucide-icon>
              <span class="text-xs font-medium">{{ parcel.createdAt | date:'dd/MM/yyyy' }}</span>
            </div>

            <div class="pt-3 mt-4 border-t border-gray-50 flex justify-end">
              <button (click)="openPassport(parcel.id)" class="px-4 py-2 bg-primary/10 text-primary hover:bg-primary hover:text-white rounded-xl text-xs font-black transition-all flex items-center gap-1.5">
                <lucide-icon name="file-text" class="w-4 h-4"></lucide-icon>
                PASSEPORT PARCELLE
              </button>
            </div>
          </div>
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

  private parcelService = inject(ParcelService);

  ngOnInit() {
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
    window.open('http://localhost:3000/parcels/passport/' + id, '_blank');
  }
}
