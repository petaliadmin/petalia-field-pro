import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';

export type UserRole = 'ADMIN' | 'EXPERT' | 'TECHNICIAN';

export interface AuthUser {
  id: string;
  name: string;
  phone: string;
  role: UserRole;
}

export interface LoginResponse {
  access_token: string;
  user: AuthUser;
}

const TOKEN_KEY = 'petalia_admin_token';
const USER_KEY = 'petalia_admin_user';

/**
 * Source de vérité de l'authentification côté admin.
 * Stocke le JWT + l'utilisateur courant et expose un signal `currentUser`
 * que les guards/composants peuvent observer.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  private readonly userSignal = signal<AuthUser | null>(this.readStoredUser());
  readonly currentUser = this.userSignal.asReadonly();
  readonly isAuthenticated = computed(() => this.userSignal() !== null);
  readonly isAdmin = computed(() => this.userSignal()?.role === 'ADMIN');

  login(phone: string, pin: string): Observable<LoginResponse> {
    return this.http
      .post<LoginResponse>(`${environment.apiUrl}/auth/login`, { phone, pin })
      .pipe(tap((res) => this.persistSession(res)));
  }

  logout(redirect = true): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    this.userSignal.set(null);
    if (redirect) {
      this.router.navigate(['/login']);
    }
  }

  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY);
  }

  /**
   * Garde-fou : un utilisateur non-ADMIN ne devrait jamais traverser
   * le portail admin même s'il s'authentifie avec succès.
   */
  enforceAdminOnly(user: AuthUser): boolean {
    if (user.role !== 'ADMIN') {
      this.logout(false);
      return false;
    }
    return true;
  }

  private persistSession(res: LoginResponse): void {
    localStorage.setItem(TOKEN_KEY, res.access_token);
    localStorage.setItem(USER_KEY, JSON.stringify(res.user));
    this.userSignal.set(res.user);
  }

  private readStoredUser(): AuthUser | null {
    try {
      const raw = localStorage.getItem(USER_KEY);
      return raw ? (JSON.parse(raw) as AuthUser) : null;
    } catch {
      return null;
    }
  }
}
