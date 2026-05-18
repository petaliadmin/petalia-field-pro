import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

/**
 * Bloque l'accès aux routes protégées si :
 *  - aucun token/utilisateur en session
 *  - l'utilisateur connecté n'a pas le rôle ADMIN (back-office réservé).
 * Redirige sinon vers /login.
 */
export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  const user = auth.currentUser();
  if (!user) {
    router.navigate(['/login']);
    return false;
  }

  if (!auth.enforceAdminOnly(user)) {
    router.navigate(['/login'], {
      queryParams: { reason: 'admin-only' },
    });
    return false;
  }

  return true;
};

/**
 * Empêche un utilisateur déjà connecté de revoir l'écran de login.
 */
export const guestGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated() && auth.isAdmin()) {
    router.navigate(['/dashboard']);
    return false;
  }
  return true;
};
