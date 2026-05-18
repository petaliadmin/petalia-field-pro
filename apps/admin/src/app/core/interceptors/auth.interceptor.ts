import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { environment } from '../../../environments/environment';
import { AuthService } from '../services/auth.service';

/**
 * Injecte automatiquement le JWT (Bearer) sur toutes les requêtes
 * sortantes vers l'API Petalia. Les autres origines (CDN, tuiles
 * carto…) restent intactes pour ne pas leaker le token.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.getToken();

  const isApiCall = req.url.startsWith(environment.apiUrl);
  if (!token || !isApiCall) {
    return next(req);
  }

  const cloned = req.clone({
    setHeaders: { Authorization: `Bearer ${token}` },
  });
  return next(cloned);
};
