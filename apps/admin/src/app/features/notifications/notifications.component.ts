import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { NotificationService, SendNotificationPayload } from '../../core/services/notification.service';
import { UserService, UserAccount } from '../../core/services/user.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [CommonModule, FormsModule, LucideAngularModule],
  template: `
    <div class="max-w-6xl mx-auto space-y-8 animate-fade-in">
      <!-- Header -->
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-8 rounded-[32px] shadow-sm border border-slate-100">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 bg-primary/10 rounded-2xl flex items-center justify-center text-primary">
            <lucide-icon name="send" class="w-8 h-8"></lucide-icon>
          </div>
          <div>
            <h1 class="text-2xl font-black text-slate-900 tracking-tight">Centre de Notifications Push</h1>
            <p class="text-sm text-slate-500 font-medium">Diffusez des alertes instantanées sur les terminaux mobiles de la flotte</p>
          </div>
        </div>
        <div class="flex items-center gap-3 bg-slate-50 px-5 py-3 rounded-2xl border border-slate-100">
          <lucide-icon name="radio" class="w-5 h-5 text-emerald-500 animate-pulse"></lucide-icon>
          <span class="text-xs font-bold text-slate-700 uppercase tracking-wider">Passerelle FCM Active</span>
        </div>
      </div>

      <!-- Main Layout: Form + Live Mobile Preview -->
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        
        <!-- Form Area (8 cols) -->
        <div class="lg:col-span-7 space-y-8">
          
          <!-- Mode de Ciblage -->
          <div class="bg-white p-8 rounded-[32px] shadow-sm border border-slate-100 space-y-6">
            <h2 class="text-lg font-black text-slate-900 flex items-center gap-2">
              <lucide-icon name="target" class="w-5 h-5 text-primary"></lucide-icon>
              1. Mode de Ciblage
            </h2>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <!-- Cible: ALL -->
              <label 
                class="flex flex-col p-5 rounded-2xl border-2 cursor-pointer transition-all"
                [ngClass]="targetMode === 'ALL' ? 'border-primary bg-primary/5 shadow-md shadow-primary/5' : 'border-slate-100 bg-white hover:border-slate-200'">
                <div class="flex items-center justify-between mb-3">
                  <div class="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                    <lucide-icon name="users" class="w-5 h-5"></lucide-icon>
                  </div>
                  <input type="radio" name="targetMode" value="ALL" [(ngModel)]="targetMode" class="w-5 h-5 text-primary focus:ring-primary">
                </div>
                <span class="font-black text-slate-900 text-sm mb-1">Diffusion Collective (Multicast)</span>
                <span class="text-xs text-slate-500 font-medium leading-relaxed">Envoi simultané à l'ensemble des producteurs et techniciens actifs.</span>
              </label>

              <!-- Cible: INDIVIDUAL -->
              <label 
                class="flex flex-col p-5 rounded-2xl border-2 cursor-pointer transition-all"
                [ngClass]="targetMode === 'INDIVIDUAL' ? 'border-primary bg-primary/5 shadow-md shadow-primary/5' : 'border-slate-100 bg-white hover:border-slate-200'">
                <div class="flex items-center justify-between mb-3">
                  <div class="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                    <lucide-icon name="user-check" class="w-5 h-5"></lucide-icon>
                  </div>
                  <input type="radio" name="targetMode" value="INDIVIDUAL" [(ngModel)]="targetMode" class="w-5 h-5 text-primary focus:ring-primary">
                </div>
                <span class="font-black text-slate-900 text-sm mb-1">Ciblage Individuel</span>
                <span class="text-xs text-slate-500 font-medium leading-relaxed">Envoi ciblé sur un utilisateur spécifique ou un token FCM direct.</span>
              </label>
            </div>

            <!-- Sélection de l'utilisateur (si INDIVIDUAL) -->
            <div *ngIf="targetMode === 'INDIVIDUAL'" class="space-y-4 pt-4 border-t border-slate-100 animate-fade-in">
              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Sélectionner un utilisateur cible</label>
                <select [(ngModel)]="selectedUserId" class="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
                  <option value="">-- Choisir un utilisateur dans la liste --</option>
                  <option *ngFor="let user of users" [value]="user.id">
                    {{ user.name }} ({{ user.role }}) - {{ user.email }}
                  </option>
                </select>
              </div>

              <div class="flex items-center gap-4">
                <div class="h-px bg-slate-200 flex-1"></div>
                <span class="text-xs font-bold text-slate-400 uppercase">OU</span>
                <div class="h-px bg-slate-200 flex-1"></div>
              </div>

              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Saisir un Token FCM Direct (Optionnel)</label>
                <input [(ngModel)]="manualFcmToken" type="text" placeholder="Ex: eXk9_... (Remplace la sélection utilisateur)" class="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
              </div>
            </div>
          </div>

          <!-- Modèles Rapides (Presets) -->
          <div class="bg-white p-8 rounded-[32px] shadow-sm border border-slate-100 space-y-6">
            <h2 class="text-lg font-black text-slate-900 flex items-center gap-2">
              <lucide-icon name="sparkles" class="w-5 h-5 text-accent"></lucide-icon>
              2. Modèles d'Alertes Rapides
            </h2>
            <div class="flex flex-wrap gap-3">
              <button (click)="applyPreset('METEO')" class="flex items-center gap-2 px-4 py-2.5 bg-amber-50 border border-amber-200 rounded-xl text-xs font-bold text-amber-700 hover:bg-amber-100 transition-all">
                <lucide-icon name="cloud-lightning" class="w-4 h-4"></lucide-icon>
                Alerte Météo (Pluie/Lessivage)
              </button>
              <button (click)="applyPreset('EXPERT')" class="flex items-center gap-2 px-4 py-2.5 bg-blue-50 border border-blue-200 rounded-xl text-xs font-bold text-blue-700 hover:bg-blue-100 transition-all">
                <lucide-icon name="user-check" class="w-4 h-4"></lucide-icon>
                Avis d'Expert Disponible
              </button>
              <button (click)="applyPreset('MAINTENANCE')" class="flex items-center gap-2 px-4 py-2.5 bg-purple-50 border border-purple-200 rounded-xl text-xs font-bold text-purple-700 hover:bg-purple-100 transition-all">
                <lucide-icon name="settings" class="w-4 h-4"></lucide-icon>
                Maintenance Serveur
              </button>
              <button (click)="applyPreset('CREDIT')" class="flex items-center gap-2 px-4 py-2.5 bg-emerald-50 border border-emerald-200 rounded-xl text-xs font-bold text-emerald-700 hover:bg-emerald-100 transition-all">
                <lucide-icon name="wallet" class="w-4 h-4"></lucide-icon>
                Crédits Rechargés
              </button>
            </div>
          </div>

          <!-- Contenu du Message -->
          <div class="bg-white p-8 rounded-[32px] shadow-sm border border-slate-100 space-y-6">
            <h2 class="text-lg font-black text-slate-900 flex items-center gap-2">
              <lucide-icon name="message-square-text" class="w-5 h-5 text-primary"></lucide-icon>
              3. Contenu de la Notification
            </h2>

            <div class="space-y-4">
              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Titre de la notification <span class="text-red-500">*</span></label>
                <input [(ngModel)]="notificationTitle" type="text" placeholder="Ex: Alerte Phytosanitaire : Chenille Légionnaire" class="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
              </div>

              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Corps du message <span class="text-red-500">*</span></label>
                <textarea [(ngModel)]="notificationBody" rows="4" placeholder="Ex: Un foyer de chenille légionnaire a été détecté dans la zone des Niayes. Inspectez vos parcelles de maïs." class="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all"></textarea>
              </div>

              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Données Additionnelles (Payload JSON Optionnel)</label>
                <input [(ngModel)]="customDataJson" type="text" placeholder='Ex: {"click_action": "FLUTTER_NOTIFICATION_CLICK", "route": "/alerts"}' class="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-700 focus:bg-white focus:border-primary/20 outline-none transition-all">
                <p class="text-[11px] text-slate-400 mt-1 font-medium">Paires clé-valeur transmises silencieusement à l'application mobile pour redirection ou traitement.</p>
              </div>
            </div>

            <!-- Action d'envoi -->
            <div class="pt-6 border-t border-slate-100">
              <button 
                (click)="sendPush()" 
                [disabled]="isSending || !notificationTitle || !notificationBody || (targetMode === 'INDIVIDUAL' && !selectedUserId && !manualFcmToken)"
                class="w-full py-4 bg-primary text-white rounded-2xl font-black text-sm shadow-xl shadow-primary/20 hover:bg-primary-dark transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none flex items-center justify-center gap-3">
                <lucide-icon *ngIf="!isSending" name="send" class="w-5 h-5"></lucide-icon>
                <lucide-icon *ngIf="isSending" name="loader-2" class="w-5 h-5 animate-spin"></lucide-icon>
                <span>{{ isSending ? 'DIFFUSION EN COURS...' : 'DIFFUSER LA NOTIFICATION PUSH' }}</span>
              </button>
            </div>
          </div>

        </div>

        <!-- Live Mobile Preview Area (5 cols) -->
        <div class="lg:col-span-5 space-y-6">
          <div class="sticky top-8 bg-slate-900 p-8 rounded-[36px] shadow-2xl border-4 border-slate-800 text-white space-y-6">
            <div class="flex items-center justify-between border-b border-slate-800 pb-4">
              <div class="flex items-center gap-2">
                <lucide-icon name="smartphone" class="w-5 h-5 text-accent"></lucide-icon>
                <span class="text-xs font-bold uppercase tracking-wider text-slate-400">Aperçu Smartphone (Temps Réel)</span>
              </div>
              <div class="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></div>
            </div>

            <!-- Mobile Screen Mockup -->
            <div class="bg-slate-950 rounded-[28px] p-6 border border-slate-800 min-h-[380px] flex flex-col justify-between shadow-inner relative overflow-hidden">
              <!-- Wallpaper Gradient simulation -->
              <div class="absolute inset-0 bg-gradient-to-tr from-primary/10 via-transparent to-accent/10 opacity-50 pointer-events-none"></div>

              <!-- Top Bar Mockup -->
              <div class="flex items-center justify-between text-[11px] font-bold text-slate-400 mb-6 relative z-10">
                <span>12:30</span>
                <div class="flex items-center gap-1.5">
                  <lucide-icon name="wifi" class="w-3.5 h-3.5"></lucide-icon>
                  <lucide-icon name="battery-charging" class="w-3.5 h-3.5 text-emerald-500"></lucide-icon>
                </div>
              </div>

              <!-- Notification Banner Mockup -->
              <div class="bg-slate-900/90 backdrop-blur-md rounded-2xl p-4 border border-slate-700/50 shadow-2xl space-y-3 relative z-10 animate-fade-in">
                <!-- App Info -->
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <div class="w-6 h-6 rounded-lg bg-primary flex items-center justify-center text-white text-[10px] font-black shadow-md shadow-primary/30">
                      P
                    </div>
                    <span class="text-xs font-black tracking-tight text-slate-200">Petalia Field Pro</span>
                  </div>
                  <span class="text-[10px] font-bold text-slate-400">À l'instant</span>
                </div>

                <!-- Title & Body -->
                <div class="space-y-1 pl-1">
                  <p class="text-xs font-bold text-white line-clamp-1">
                    {{ notificationTitle || 'Titre de la notification...' }}
                  </p>
                  <p class="text-[11px] text-slate-300 font-medium leading-relaxed line-clamp-3">
                    {{ notificationBody || 'Corps du message affiché sur l\'écran de verrouillage ou dans le centre de notifications...' }}
                  </p>
                </div>
              </div>

              <!-- Bottom Hint -->
              <div class="text-center text-[10px] font-bold text-slate-500 pt-6 border-t border-slate-900 relative z-10">
                Glissez vers le haut pour déverrouiller
              </div>
            </div>

            <!-- Recap Card -->
            <div class="bg-slate-800/50 rounded-2xl p-5 border border-slate-700/50 space-y-3 text-xs font-medium text-slate-300">
              <div class="flex justify-between py-1 border-b border-slate-700/50">
                <span class="text-slate-400">Mode d'envoi :</span>
                <span class="font-bold text-white">{{ targetMode === 'ALL' ? 'Multicast (Tous)' : 'Individuel' }}</span>
              </div>
              <div class="flex justify-between py-1 border-b border-slate-700/50">
                <span class="text-slate-400">Destinataires :</span>
                <span class="font-bold text-accent">{{ targetMode === 'ALL' ? 'Flotte complète' : (selectedUserId ? '1 utilisateur' : 'Token manuel') }}</span>
              </div>
              <div class="flex justify-between py-1">
                <span class="text-slate-400">Action au clic :</span>
                <span class="font-bold text-emerald-400">Ouverture de l'application</span>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  `
})
export class NotificationsComponent implements OnInit {
  targetMode: 'ALL' | 'INDIVIDUAL' = 'ALL';
  users: UserAccount[] = [];
  selectedUserId = '';
  manualFcmToken = '';

  notificationTitle = '';
  notificationBody = '';
  customDataJson = '{"click_action": "FLUTTER_NOTIFICATION_CLICK"}';

  isSending = false;

  private notificationService = inject(NotificationService);
  private userService = inject(UserService);
  private alertConfirmService = inject(AlertConfirmService);

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    this.userService.getAll().subscribe({
      next: (res) => {
        this.users = res.filter(u => u.status === 'ACTIVE');
      },
      error: () => {
        this.alertConfirmService.error('Erreur lors du chargement des utilisateurs.');
      }
    });
  }

  applyPreset(type: 'METEO' | 'EXPERT' | 'MAINTENANCE' | 'CREDIT') {
    switch (type) {
      case 'METEO':
        this.notificationTitle = '⚠️ Alerte Météo : Risque de Lessivage';
        this.notificationBody = 'Des pluies supérieures à 5mm sont prévues dans les prochaines 6 heures. Repoussez vos pulvérisations phytosanitaires.';
        this.customDataJson = '{"click_action": "FLUTTER_NOTIFICATION_CLICK", "route": "/alerts"}';
        break;
      case 'EXPERT':
        this.notificationTitle = '👨‍🌾 Avis d\'Expert Disponible';
        this.notificationBody = 'Un agronome de l\'ISRA a répondu à votre demande d\'assistance. Consultez ses recommandations dans l\'application.';
        this.customDataJson = '{"click_action": "FLUTTER_NOTIFICATION_CLICK", "route": "/expert-requests"}';
        break;
      case 'MAINTENANCE':
        this.notificationTitle = '⚙️ Maintenance Serveur Petalia';
        this.notificationBody = 'Une mise à jour des serveurs aura lieu ce soir à 23h00. Le mode hors-ligne reste 100% fonctionnel sur le terrain.';
        this.customDataJson = '{"click_action": "FLUTTER_NOTIFICATION_CLICK"}';
        break;
      case 'CREDIT':
        this.notificationTitle = '💳 Crédits Agronomiques Rechargés';
        this.notificationBody = 'Votre portefeuille a été rechargé par l\'administration. Vous pouvez désormais effectuer de nouvelles analyses NDVI et IA.';
        this.customDataJson = '{"click_action": "FLUTTER_NOTIFICATION_CLICK", "route": "/wallet"}';
        break;
    }
    this.alertConfirmService.success('Modèle appliqué avec succès.');
  }

  sendPush() {
    if (!this.notificationTitle || !this.notificationBody) {
      this.alertConfirmService.error('Le titre et le corps du message sont obligatoires.');
      return;
    }

    let parsedData: any = {};
    if (this.customDataJson) {
      try {
        parsedData = JSON.parse(this.customDataJson);
      } catch (e) {
        this.alertConfirmService.error('Le format JSON des données additionnelles est invalide.');
        return;
      }
    }

    const payload: SendNotificationPayload = {
      target: this.targetMode,
      title: this.notificationTitle,
      body: this.notificationBody,
      data: parsedData,
    };

    if (this.targetMode === 'INDIVIDUAL') {
      if (this.manualFcmToken) {
        payload.fcmToken = this.manualFcmToken;
      } else if (this.selectedUserId) {
        payload.userId = this.selectedUserId;
      } else {
        this.alertConfirmService.error('Veuillez sélectionner un utilisateur ou saisir un token FCM.');
        return;
      }
    }

    this.isSending = true;
    this.notificationService.sendPushNotification(payload).subscribe({
      next: (res) => {
        this.isSending = false;
        if (res.success) {
          this.alertConfirmService.success(res.message || 'Notification push envoyée avec succès.');
          // Reset form
          this.notificationTitle = '';
          this.notificationBody = '';
        } else {
          this.alertConfirmService.error(res.message || 'Échec de l\'envoi de la notification.');
        }
      },
      error: (err) => {
        this.isSending = false;
        this.alertConfirmService.error(err.error?.message || 'Erreur lors de la diffusion push.');
      }
    });
  }
}
