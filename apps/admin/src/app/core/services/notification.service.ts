import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface SendNotificationPayload {
  target: 'ALL' | 'INDIVIDUAL';
  userId?: string;
  fcmToken?: string;
  title: string;
  body: string;
  data?: any;
}

export interface SendNotificationResponse {
  success: boolean;
  message: string;
  targetCount?: number;
  targetToken?: string;
}

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/notifications`;

  sendPushNotification(payload: SendNotificationPayload): Observable<SendNotificationResponse> {
    return this.http.post<SendNotificationResponse>(`${this.apiUrl}/send`, payload);
  }
}
