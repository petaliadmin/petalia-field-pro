import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { LucideAngularModule } from 'lucide-angular';
import { forkJoin } from 'rxjs';
import { DiagnosticService, DiagnosticRequest } from '../../core/services/diagnostic.service';
import { UserService } from '../../core/services/user.service';
import { ParcelService } from '../../core/services/parcel.service';

interface DashboardStats {
  parcelsCount: number;
  pendingAlerts: number;
  activeTechnicians: number;
  validationRate: number;
}

interface DiagnosticStatusBreakdown {
  pending: number;
  analyzed: number;
  validated: number;
  rejected: number;
  total: number;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink, LucideAngularModule],
  template: `
    <div class="space-y-8">
      <div>
        <h2 class="text-3xl font-black text-slate-900 tracking-tight">Tableau de bord</h2>
        <p class="text-slate-500 font-medium">État actuel du réseau agricole Petalia.</p>
      </div>

      <!-- Loading State -->
      <div *ngIf="loading" class="grid grid-cols-4 gap-6">
        <div *ngFor="let i of [1,2,3,4]" class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm animate-pulse">
          <div class="w-12 h-12 bg-slate-100 rounded-2xl mb-4"></div>
          <div class="h-3 bg-slate-100 rounded w-20 mb-3"></div>
          <div class="h-8 bg-slate-100 rounded w-16"></div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div *ngIf="!loading" class="grid grid-cols-4 gap-6">
        <div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
          <div class="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center text-primary mb-4">
            <lucide-icon name="map-pin" class="w-6 h-6"></lucide-icon>
          </div>
          <p class="text-xs font-black text-slate-400 uppercase tracking-widest mb-1">Parcelles</p>
          <h3 class="text-3xl font-black text-slate-900">{{ stats.parcelsCount | number }}</h3>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
          <div class="w-12 h-12 bg-amber-100 rounded-2xl flex items-center justify-center text-amber-600 mb-4">
            <lucide-icon name="microscope" class="w-6 h-6"></lucide-icon>
          </div>
          <p class="text-xs font-black text-slate-400 uppercase tracking-widest mb-1">Alertes en attente</p>
          <div class="flex items-end gap-3">
            <h3 class="text-3xl font-black text-slate-900">{{ stats.pendingAlerts }}</h3>
            <span *ngIf="stats.pendingAlerts > 0" class="text-amber-500 text-xs font-bold mb-1 italic">Action requise</span>
          </div>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
          <div class="w-12 h-12 bg-blue-100 rounded-2xl flex items-center justify-center text-blue-600 mb-4">
            <lucide-icon name="users" class="w-6 h-6"></lucide-icon>
          </div>
          <p class="text-xs font-black text-slate-400 uppercase tracking-widest mb-1">Techniciens actifs</p>
          <h3 class="text-3xl font-black text-slate-900">{{ stats.activeTechnicians }}</h3>
        </div>

        <div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
          <div class="w-12 h-12 bg-emerald-100 rounded-2xl flex items-center justify-center text-emerald-600 mb-4">
            <lucide-icon name="circle-check" class="w-6 h-6"></lucide-icon>
          </div>
          <p class="text-xs font-black text-slate-400 uppercase tracking-widest mb-1">Taux de validation</p>
          <div class="flex items-end gap-3">
            <h3 class="text-3xl font-black text-slate-900">{{ stats.validationRate }}%</h3>
            <span class="text-emerald-500 text-xs font-bold mb-1">Efficacité</span>
          </div>
        </div>
      </div>

      <div *ngIf="!loading" class="grid grid-cols-12 gap-8">
        <!-- Recent Activity -->
        <div class="col-span-8 bg-white rounded-3xl p-8 border border-gray-100 shadow-sm">
          <div class="flex items-center justify-between mb-8">
            <h3 class="text-xl font-black text-slate-900">Activités Récentes</h3>
            <a routerLink="/diagnostics" class="text-sm font-bold text-primary hover:underline">Voir tout</a>
          </div>

          <div *ngIf="recentActivity.length === 0" class="text-center py-8">
            <lucide-icon name="clock" class="w-10 h-10 text-slate-200 mx-auto mb-3"></lucide-icon>
            <p class="text-slate-400 font-bold">Aucune activité récente</p>
          </div>

          <div class="space-y-6">
            <div *ngFor="let diag of recentActivity" class="flex items-start gap-4">
              <div class="w-10 h-10 rounded-full bg-gray-50 flex items-center justify-center text-slate-400 shrink-0">
                <lucide-icon name="clock" class="w-5 h-5"></lucide-icon>
              </div>
              <div class="flex-1 border-b border-gray-50 pb-4">
                <p class="text-sm text-slate-600 leading-relaxed font-medium">
                  <span class="font-bold text-slate-900">{{ diag.ownerName }}</span>
                  a soumis un diagnostic pour la parcelle
                  <span class="font-bold text-primary">#{{ diag.parcelId | slice:0:8 }}</span>.
                </p>
                <div class="flex items-center gap-3 mt-1">
                  <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                    {{ diag.createdAt | date:'dd/MM/yyyy HH:mm' }}
                  </span>
                  <span class="text-[10px] font-black px-2 py-0.5 rounded-full"
                        [ngClass]="{
                          'bg-amber-100 text-amber-700': diag.status === 'pending',
                          'bg-blue-100 text-blue-700': diag.status === 'analyzed',
                          'bg-emerald-100 text-emerald-700': diag.status === 'validated',
                          'bg-red-100 text-red-700': diag.status === 'rejected'
                        }">
                    {{ diag.status | uppercase }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Diagnostic Status Breakdown -->
        <div class="col-span-4 bg-primary rounded-3xl p-8 text-white shadow-xl shadow-primary/20 relative overflow-hidden">
          <div class="relative z-10">
            <h3 class="text-xl font-black mb-2">Diagnostics</h3>
            <p class="text-white/70 text-sm font-medium mb-8">{{ breakdown.total }} demandes au total</p>

            <div class="space-y-5">
              <div>
                <div class="flex justify-between text-xs font-black uppercase tracking-widest mb-2">
                  <span>En attente</span>
                  <span>{{ breakdown.pending }}</span>
                </div>
                <div class="w-full h-1.5 bg-white/20 rounded-full overflow-hidden">
                  <div class="h-full bg-amber-300 transition-all duration-700"
                       [style.width.%]="breakdown.total > 0 ? (breakdown.pending / breakdown.total * 100) : 0"></div>
                </div>
              </div>
              <div>
                <div class="flex justify-between text-xs font-black uppercase tracking-widest mb-2">
                  <span>Analysés</span>
                  <span>{{ breakdown.analyzed }}</span>
                </div>
                <div class="w-full h-1.5 bg-white/20 rounded-full overflow-hidden">
                  <div class="h-full bg-blue-300 transition-all duration-700"
                       [style.width.%]="breakdown.total > 0 ? (breakdown.analyzed / breakdown.total * 100) : 0"></div>
                </div>
              </div>
              <div>
                <div class="flex justify-between text-xs font-black uppercase tracking-widest mb-2">
                  <span>Validés</span>
                  <span>{{ breakdown.validated }}</span>
                </div>
                <div class="w-full h-1.5 bg-white/20 rounded-full overflow-hidden">
                  <div class="h-full bg-white transition-all duration-700"
                       [style.width.%]="breakdown.total > 0 ? (breakdown.validated / breakdown.total * 100) : 0"></div>
                </div>
              </div>
              <div>
                <div class="flex justify-between text-xs font-black uppercase tracking-widest mb-2">
                  <span>Rejetés</span>
                  <span>{{ breakdown.rejected }}</span>
                </div>
                <div class="w-full h-1.5 bg-white/20 rounded-full overflow-hidden">
                  <div class="h-full bg-red-300 transition-all duration-700"
                       [style.width.%]="breakdown.total > 0 ? (breakdown.rejected / breakdown.total * 100) : 0"></div>
                </div>
              </div>
            </div>

            <a routerLink="/diagnostics" class="block w-full mt-10 py-3 bg-white text-primary rounded-2xl font-black text-sm hover:bg-gray-100 transition-all text-center">
              Gérer les diagnostics
            </a>
          </div>

          <div class="absolute -bottom-20 -right-20 w-64 h-64 bg-white/10 rounded-full blur-3xl"></div>
        </div>
      </div>
    </div>
  `,
})
export class DashboardComponent implements OnInit {
  loading = true;
  stats: DashboardStats = { parcelsCount: 0, pendingAlerts: 0, activeTechnicians: 0, validationRate: 0 };
  recentActivity: DiagnosticRequest[] = [];
  breakdown: DiagnosticStatusBreakdown = { pending: 0, analyzed: 0, validated: 0, rejected: 0, total: 0 };

  private diagnosticService = inject(DiagnosticService);
  private userService = inject(UserService);
  private parcelService = inject(ParcelService);

  ngOnInit() {
    forkJoin({
      diagnostics: this.diagnosticService.getAll(),
      users: this.userService.getAll(),
      parcels: this.parcelService.getAll()
    }).subscribe({
      next: ({ diagnostics, users, parcels }) => {
        const pending = diagnostics.filter(d => d.status === 'pending').length;
        const analyzed = diagnostics.filter(d => d.status === 'analyzed').length;
        const validated = diagnostics.filter(d => d.status === 'validated').length;
        const rejected = diagnostics.filter(d => d.status === 'rejected').length;

        this.stats = {
          parcelsCount: parcels.length,
          pendingAlerts: pending,
          activeTechnicians: users.filter(u => u.status === 'ACTIVE' && u.role !== 'ADMIN').length,
          validationRate: diagnostics.length > 0 ? Math.round((validated / diagnostics.length) * 100) : 0
        };

        this.breakdown = { pending, analyzed, validated, rejected, total: diagnostics.length };

        this.recentActivity = [...diagnostics]
          .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
          .slice(0, 5);

        this.loading = false;
      },
      error: () => { this.loading = false; }
    });
  }
}
