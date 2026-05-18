import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthService } from '../services/auth.service';
import { AlertConfirmService } from '../services/alert-confirm.service';

/**
 * Pipeline d'erreurs HTTP global :
 *  - 401 : session expirée → on purge le token et on redirige sur /login
 *  - 400 contenant "solde" : feedback dédié pour les flux de facturation wallet
 *  - 0 (réseau) : alerte « serveur injoignable »
 *  - 5xx       : alerte serveur générique
 * Les composants reçoivent toujours l'erreur originale pour leur logique locale.
 */
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const alerts = inject(AlertConfirmService);

  const isApiCall = req.url.startsWith(environment.apiUrl);

  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      if (!isApiCall) {
        return throwError(() => err);
      }

      const backendMessage: string = err?.error?.message || err?.message || '';

      switch (err.status) {
        case 0:
          alerts.error('Serveur Petalia injoignable. Vérifiez votre connexion.');
          break;

        case 401: {
          // Ne pas spammer l'alerte sur l'écran de login
          if (!router.url.startsWith('/login')) {
            alerts.warning('Session expirée. Veuillez vous reconnecter.');
          }
          auth.logout();
          break;
        }

        case 400: {
          // Cas spécifique : débit wallet refusé pour solde insuffisant
          if (/solde/i.test(backendMessage)) {
            alerts.error(
              backendMessage ||
                'Solde de crédits insuffisant pour cette opération.',
              'Crédits insuffisants',
            );
          } else {
            alerts.error(backendMessage || 'Requête invalide');
          }
          break;
        }

        case 403:
          alerts.error("Action interdite (droits insuffisants)");
          break;

        case 404:
          // Laisser les composants gérer le 404 selon le contexte
          break;

        default:
          if (err.status >= 500) {
            alerts.error(
              backendMessage || 'Erreur serveur. Réessayez dans un instant.',
              'Erreur serveur',
            );
          }
          break;
      }

      return throwError(() => err);
    }),
  );
};
