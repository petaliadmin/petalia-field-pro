import { Component, OnInit, inject } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { CommonModule } from '@angular/common';
import { LucideAngularModule } from 'lucide-angular';
import { filter, map } from 'rxjs/operators';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, CommonModule, LucideAngularModule],
  template: `
    <div class="flex h-screen bg-slate-50 font-sans text-slate-900">
      <!-- Sidebar -->
      <aside class="w-72 bg-white border-r border-slate-200 flex flex-col p-8 gap-10">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg shadow-primary/20">
            <lucide-icon name="microscope" class="w-6 h-6"></lucide-icon>
          </div>
          <h1 class="text-xl font-black tracking-tighter uppercase">Petalia <span class="text-primary">Admin</span></h1>
        </div>

        <nav class="flex flex-col gap-2 flex-1">
          <a routerLink="/dashboard" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all group">
            <lucide-icon name="layout-dashboard" class="w-5 h-5"></lucide-icon>
            Tableau de Bord
          </a>
          <a routerLink="/diagnostics" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all group">
            <lucide-icon name="microscope" class="w-5 h-5"></lucide-icon>
            Diagnostics Experts
          </a>
          <a routerLink="/parcels" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all group">
            <lucide-icon name="map" class="w-5 h-5"></lucide-icon>
            Carte des Parcelles
          </a>
          <a routerLink="/users" routerLinkActive="bg-primary/10 text-primary" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all group">
            <lucide-icon name="wallet" class="w-5 h-5"></lucide-icon>
            Gestion des Comptes
          </a>
        </nav>

        <div class="flex flex-col gap-2 pt-8 border-t border-slate-100">
          <a href="#" class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-slate-500 hover:bg-slate-50 transition-all">
            <lucide-icon name="settings" class="w-5 h-5"></lucide-icon>
            Configuration
          </a>
          <button class="flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-red-500 hover:bg-red-50 transition-all">
            <lucide-icon name="log-out" class="w-5 h-5"></lucide-icon>
            Déconnexion
          </button>
        </div>
      </aside>

      <!-- Main Content -->
      <main class="flex-1 flex flex-col overflow-hidden">
        <!-- Top Bar -->
        <header class="h-20 bg-white border-b border-slate-200 px-8 flex items-center justify-between shrink-0">
          <div class="flex items-center gap-2 text-sm font-bold text-slate-400">
             <span class="hover:text-primary cursor-pointer transition-colors">Admin</span>
             <span>/</span>
             <span class="text-slate-900 capitalize">{{ currentPath }}</span>
          </div>

          <div class="flex items-center gap-6">
            <button class="relative w-10 h-10 flex items-center justify-center text-slate-400 hover:text-primary transition-colors">
              <lucide-icon name="bell" class="w-5 h-5"></lucide-icon>
              <span class="absolute top-2 right-2 w-2 h-2 bg-accent rounded-full border-2 border-white"></span>
            </button>
            <div class="flex items-center gap-3 pl-6 border-l border-slate-100">
              <div class="text-right">
                <p class="text-sm font-black leading-tight">Mamadou Diop</p>
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Expert Agronome</p>
              </div>
              <div class="w-10 h-10 rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-400">
                <lucide-icon name="user" class="w-5 h-5"></lucide-icon>
              </div>
            </div>
          </div>
        </header>

        <!-- Scrollable Content Area -->
        <div class="flex-1 overflow-y-auto p-8">
          <router-outlet></router-outlet>
        </div>
      </main>
    </div>
  `
})
export class AppComponent implements OnInit {
  currentPath = 'dashboard';
  private router = inject(Router);

  ngOnInit() {
    this.router.events.pipe(
      filter(e => e instanceof NavigationEnd),
      map(e => (e as NavigationEnd).urlAfterRedirects.replace('/', '').split('/')[0] || 'dashboard')
    ).subscribe(path => this.currentPath = path);
  }
}
