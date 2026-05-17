import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface ExpertRequestItem {
  id: string;
  parcel: { id: string; name: string; owner: string; phone: string; village: string };
  expert: { id: string; name: string; specialization: string };
  status: 'pending' | 'paid' | 'completed' | 'cancelled';
  paymentReference?: string;
  expertAdvice?: string;
  createdAt: string;
}

@Injectable({ providedIn: 'root' })
export class ExpertRequestsService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/experts`;

  getAllRequests(): Observable<ExpertRequestItem[]> {
    return this.http.get<ExpertRequestItem[]>(`${this.apiUrl}/all-requests`);
  }

  respond(id: string, expertAdvice: string, status: 'completed' | 'cancelled'): Observable<any> {
    return this.http.patch(`${this.apiUrl}/request/${id}/respond`, { expertAdvice, status });
  }
}
