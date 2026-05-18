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
  templateUrl: './notifications.component.html'
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

  // Simulateur Réaliste
  previewOS: 'ANDROID' | 'IOS' = 'ANDROID';
  previewDisplayMode: 'BANNER' | 'LOCKSCREEN' = 'BANNER';

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
