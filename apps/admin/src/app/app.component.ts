import { Component, computed, OnInit, inject } from '@angular/core';
import {
  RouterOutlet,
  RouterLink,
  RouterLinkActive,
  Router,
  NavigationEnd,
} from '@angular/router';
import { CommonModule } from '@angular/common';
import { LucideAngularModule } from 'lucide-angular';
import { filter, map } from 'rxjs/operators';
import { AlertConfirmComponent } from './shared/components/alert-confirm/alert-confirm.component';
import { AuthService } from './core/services/auth.service';
import { AlertConfirmService } from './core/services/alert-confirm.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    CommonModule,
    LucideAngularModule,
    AlertConfirmComponent,
  ],
  template: `
    <app-alert-confirm></app-alert-confirm>

    <!-- Si non-authentifié : seul le router-outlet (login) est rendu, sans chrome. -->
    <ng-container *ngIf="!isAuthenticated()">
      <router-outlet></router-outlet>
    </ng-container>

    <!-- Chrome admin : sidebar + topbar, rendu uniquement si admin connecté. -->
    <div
      *ngIf="isAuthenticated()"
      class="flex h-screen bg-slate-50 font-sans text-slate-900 animate-fade-in">
      <aside class="w-72 bg-white border-r border-slate-200 flex flex-col p-8 gap-10 shrink-0">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-primary/20">
            <lucide-icon name="microscope" class="w-6 h-6" aria-hidden="true"></lucide-icon>
          </div>
          <h1 class="text-xl font-black tracking-tighter uppercase">
            Petalia <span class="text-primary">Admin</span>
          </h1>
        </div>

        <nav class="flex flex-col gap-2 flex-1" aria-label="Navigation principale">
          <a routerLink="/dashboard" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all">
            <lucide-icon name="layout-dashboard" class="w-5 h-5" aria-hidden="true"></lucide-icon>
            Tableau de Bord
          </a>
          <a routerLink="/diagnostics" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all">
            <lucide-icon name="microscope" class="w-5 h-5" aria-hidden="true"></lucide-icon>
            Diagnostics IA Claude
          </a>
          <a routerLink="/expert-requests" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all">
            <lucide-icon name="message-square-text" class="w-5 h-5" aria-hidden="true"></lucide-icon>
            Demandes Avis Experts
          </a>
          <a routerLink="/parcels" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all">
            <lucide-icon name="map" class="w-5 h-5" aria-hidden="true"></lucide-icon>
            Carte des Parcelles
          </a>
          <a routerLink="/users" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all">
            <lucide-icon name="wallet" class="w-5 h-5" aria-hidden="true"></lucide-icon>
            Gestion des Comptes
          </a>
          <a routerLink="/notifications" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all">
            <lucide-icon name="send" class="w-5 h-5" aria-hidden="true"></lucide-icon>
            Diffusion Push FCM
          </a>
        </nav>

        <div class="flex flex-col gap-2 pt-8 border-t border-slate-100">
          <button
            (click)="logout()"
            type="button"
            class="w-full flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-red-500 hover:bg-red-50 transition-all">
            <lucide-icon name="log-out" class="w-5 h-5" aria-hidden="true"></lucide-icon>
            Déconnexion
          </button>
        </div>
      </aside>

      <main class="flex-1 flex flex-col overflow-hidden">
        <header class="h-20 bg-white border-b border-slate-200 px-8 flex items-center justify-between shrink-0">
          <div class="flex items-center gap-2 text-sm font-bold text-slate-400">
            <span class="hover:text-primary cursor-pointer transition-colors">Admin</span>
            <span>/</span>
            <span class="text-slate-900 capitalize">{{ currentPath }}</span>
          </div>

          <div class="flex items-center gap-6">
            <button
              type="button"
              aria-label="Notifications"
              class="relative w-10 h-10 flex items-center justify-center text-slate-400 hover:text-primary transition-colors">
              <lucide-icon name="bell" class="w-5 h-5" aria-hidden="true"></lucide-icon>
              <span class="absolute top-2 right-2 w-2 h-2 bg-accent rounded-full border-2 border-white"></span>
            </button>
            <div class="flex items-center gap-3 pl-6 border-l border-slate-100">
              <div class="text-right">
                <p class="text-sm font-black leading-tight">{{ currentUserName() }}</p>
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                  {{ currentUserRole() }}
                </p>
              </div>
              <div class="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-400">
                <lucide-icon name="user" class="w-5 h-5" aria-hidden="true"></lucide-icon>
              </div>
            </div>
          </div>
        </header>

        <div class="flex-1 overflow-y-auto p-8">
          <router-outlet></router-outlet>
        </div>
      </main>
    </div>
  `,
})
export class AppComponent implements OnInit {
  private router = inject(Router);
  private auth = inject(AuthService);
  private alerts = inject(AlertConfirmService);

  currentPath = 'dashboard';

  readonly isAuthenticated = computed(
    () => this.auth.isAuthenticated() && this.auth.isAdmin(),
  );
  readonly currentUserName = computed(() => this.auth.currentUser()?.name || 'Admin');
  readonly currentUserRole = computed(() => this.auth.currentUser()?.role || '');

  ngOnInit(): void {
    this.router.events
      .pipe(
        filter((e) => e instanceof NavigationEnd),
        map((e) => (e as NavigationEnd).urlAfterRedirects.replace('/', '').split('/')[0] || 'dashboard'),
      )
      .subscribe((path) => (this.currentPath = path));
  }

  logout(): void {
    this.auth.logout();
    this.alerts.success('Déconnexion effectuée');
  }
}
