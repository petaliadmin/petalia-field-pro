import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { LucideAngularModule } from 'lucide-angular';
import { AuthService } from '../../core/services/auth.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';

@Component({
  selector: 'app-login',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, FormsModule, LucideAngularModule],
  template: `
    <div class="min-h-screen bg-slate-900 flex items-center justify-center p-4 animate-fade-in">
      <div class="bg-white rounded-[32px] p-10 max-w-md w-full shadow-2xl border border-gray-100">
        <div class="flex items-center gap-3 mb-8 justify-center">
          <div class="w-12 h-12 bg-primary rounded-2xl flex items-center justify-center text-white shadow-lg shadow-primary/20">
            <lucide-icon name="microscope" class="w-7 h-7" aria-hidden="true"></lucide-icon>
          </div>
          <h1 class="text-2xl font-black tracking-tighter uppercase">
            Petalia <span class="text-primary">Admin</span>
          </h1>
        </div>

        <h2 class="text-xl font-black text-slate-900 mb-2 text-center">Connexion administrateur</h2>
        <p class="text-sm text-slate-500 mb-6 text-center font-medium">
          Veuillez vous authentifier avec vos identifiants
        </p>

        <div
          *ngIf="errorMessage()"
          role="alert"
          class="mb-6 p-4 bg-red-50 text-red-600 rounded-2xl text-sm font-bold border border-red-100 flex items-center gap-2">
          <lucide-icon name="circle-alert" class="w-5 h-5 shrink-0" aria-hidden="true"></lucide-icon>
          <span>{{ errorMessage() }}</span>
        </div>

        <form (ngSubmit)="submit()" class="space-y-4 mb-8">
          <div>
            <label for="login-phone" class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">
              Téléphone
            </label>
            <input
              id="login-phone"
              name="phone"
              [(ngModel)]="phone"
              type="tel"
              autocomplete="tel"
              placeholder="+221 7X XXX XX XX"
              [disabled]="loading()"
              required
              class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all disabled:opacity-50" />
          </div>
          <div>
            <label for="login-pin" class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">
              Code PIN
            </label>
            <input
              id="login-pin"
              name="pin"
              [(ngModel)]="pin"
              type="password"
              autocomplete="current-password"
              inputmode="numeric"
              placeholder="••••••"
              [disabled]="loading()"
              required
              class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all disabled:opacity-50" />
          </div>

          <button
            type="submit"
            [disabled]="loading() || !phone || !pin"
            class="w-full py-4 bg-primary text-white rounded-2xl font-black text-sm shadow-xl shadow-primary/20 hover:bg-primary-dark transition-all flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed">
            <lucide-icon
              *ngIf="!loading()"
              name="log-in"
              class="w-5 h-5"
              aria-hidden="true"></lucide-icon>
            <span *ngIf="loading()" class="inline-block w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
            {{ loading() ? 'CONNEXION…' : 'SE CONNECTER' }}
          </button>
        </form>

        <p class="text-xs text-slate-400 text-center font-medium">
          Accès réservé aux comptes administrateur Petalia.
        </p>
      </div>
    </div>
  `,
})
export class LoginComponent {
  private auth = inject(AuthService);
  private router = inject(Router);
  private alerts = inject(AlertConfirmService);

  phone = '';
  pin = '';
  loading = signal(false);
  errorMessage = signal<string | null>(null);

  submit(): void {
    if (this.loading()) return;
    if (!this.phone || !this.pin) {
      this.errorMessage.set('Téléphone et code PIN requis');
      return;
    }

    this.loading.set(true);
    this.errorMessage.set(null);

    const phone = this.normalizePhone(this.phone);

    this.auth.login(phone, this.pin).subscribe({
      next: (res) => {
        if (!this.auth.enforceAdminOnly(res.user)) {
          this.loading.set(false);
          this.errorMessage.set("Ce compte n'a pas les droits administrateur");
          return;
        }
        this.alerts.success('Bienvenue ' + (res.user.name || ''));
        this.router.navigate(['/dashboard']);
      },
      error: (err) => {
        this.loading.set(false);
        const status = err?.status;
        if (status === 401) {
          this.errorMessage.set('Identifiants incorrects');
        } else if (status === 0) {
          this.errorMessage.set('Serveur injoignable. Vérifiez votre connexion.');
        } else {
          this.errorMessage.set(err?.error?.message || 'Erreur de connexion');
        }
      },
    });
  }

  /**
   * Accepte les formats locaux (77XXX...) et internationaux (+221...).
   * Aligne sur le format attendu par le backend (+221XXXXXXXXX).
   */
  private normalizePhone(raw: string): string {
    const trimmed = raw.replace(/\s+/g, '');
    if (trimmed.startsWith('+')) return trimmed;
    if (trimmed.startsWith('221')) return `+${trimmed}`;
    return `+221${trimmed.replace(/^0+/, '')}`;
  }
}
