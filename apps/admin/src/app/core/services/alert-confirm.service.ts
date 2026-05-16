import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

export interface AlertMessage {
  id: string;
  type: 'success' | 'error' | 'warning';
  title: string;
  message: string;
  duration?: number;
}

export interface ConfirmDialogConfig {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  confirmButtonColor?: string;
  onConfirm: () => void;
  onCancel?: () => void;
}

@Injectable({ providedIn: 'root' })
export class AlertConfirmService {
  private alertSubject = new Subject<AlertMessage>();
  private confirmSubject = new Subject<ConfirmDialogConfig | null>();

  alerts$ = this.alertSubject.asObservable();
  confirm$ = this.confirmSubject.asObservable();

  success(message: string, title = 'Succès', duration = 4000) {
    this.alertSubject.next({ id: Math.random().toString(), type: 'success', title, message, duration });
  }

  error(message: string, title = 'Erreur', duration = 5000) {
    this.alertSubject.next({ id: Math.random().toString(), type: 'error', title, message, duration });
  }

  warning(message: string, title = 'Attention', duration = 4000) {
    this.alertSubject.next({ id: Math.random().toString(), type: 'warning', title, message, duration });
  }

  confirm(config: ConfirmDialogConfig) {
    this.confirmSubject.next(config);
  }

  closeConfirm() {
    this.confirmSubject.next(null);
  }
}
