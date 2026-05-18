import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export type ExpertRequestStatus = 'pending' | 'paid' | 'completed' | 'cancelled';

export interface ExpertRequestItem {
  id: string;
  parcel?: { id: string; name: string; owner: string; phone: string; village: string };
  expert?: { id: string; name: string; specialization: string };
  status: ExpertRequestStatus;
  paymentReference?: string;
  expertAdvice?: string;
  context?: string;
  createdAt: string;
  // Trace de facturation wallet (cf. backend commit e6beb08)
  userId?: string;
  feeAmount?: number;
  feeReference?: string;
}

@Injectable({ providedIn: 'root' })
export class ExpertRequestsService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/experts`;

  getAllRequests(): Observable<ExpertRequestItem[]> {
    return this.http.get<ExpertRequestItem[]>(`${this.apiUrl}/all-requests`);
  }

  respond(
    id: string,
    expertAdvice: string,
    status: 'completed' | 'cancelled',
  ): Observable<ExpertRequestItem> {
    return this.http.patch<ExpertRequestItem>(
      `${this.apiUrl}/request/${id}/respond`,
      { expertAdvice, status },
    );
  }
}
