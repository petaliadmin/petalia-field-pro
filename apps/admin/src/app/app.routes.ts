import { Routes } from '@angular/router';
import { authGuard, guestGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full',
  },
  {
    path: 'login',
    canActivate: [guestGuard],
    loadComponent: () =>
      import('./features/login/login.component').then((c) => c.LoginComponent),
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/dashboard/dashboard.component').then(
        (c) => c.DashboardComponent,
      ),
  },
  {
    path: 'diagnostics',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/diagnostics/diagnostics.component').then(
        (c) => c.DiagnosticsComponent,
      ),
  },
  {
    path: 'parcels',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/parcels/parcels.component').then(
        (c) => c.ParcelsComponent,
      ),
  },
  {
    path: 'users',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/users/users.component').then((c) => c.UsersComponent),
  },
  {
    path: 'expert-requests',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/expert-requests/expert-requests.component').then(
        (c) => c.ExpertRequestsComponent,
      ),
  },
  {
    path: 'notifications',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/notifications/notifications.component').then(
        (c) => c.NotificationsComponent,
      ),
  },
  {
    path: '**',
    redirectTo: 'dashboard',
  },
];
