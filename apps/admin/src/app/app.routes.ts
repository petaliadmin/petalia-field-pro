import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full'
  },
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.component').then(c => c.DashboardComponent)
  },
  {
    path: 'diagnostics',
    loadComponent: () => import('./features/diagnostics/diagnostics.component').then(c => c.DiagnosticsComponent)
  },
  {
    path: 'parcels',
    loadComponent: () => import('./features/parcels/parcels.component').then(c => c.ParcelsComponent)
  },
  {
    path: 'users',
    loadComponent: () => import('./features/users/users.component').then(c => c.UsersComponent)
  }
];
