import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface DiagnosticRequest {
  id: string;
  parcelId: string;
  ownerName: string;
  ownerPhone: string;
  photoUrl: string;
  status: 'pending' | 'analyzed' | 'validated' | 'rejected';
  createdAt: string;
  aiResult?: any;
}

@Injectable({ providedIn: 'root' })
export class DiagnosticService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/diagnostics`;

  getAll(): Observable<DiagnosticRequest[]> {
    return this.http.get<DiagnosticRequest[]>(this.apiUrl);
  }

  validate(id: string, approve: boolean, comment: string): Observable<DiagnosticRequest> {
    return this.http.patch<DiagnosticRequest>(`${this.apiUrl}/${id}/validate`, {
      approve,
      comment
    });
  }

  getStats(): Observable<any> {
    return this.http.get(`${this.apiUrl}/stats`);
  }
}
