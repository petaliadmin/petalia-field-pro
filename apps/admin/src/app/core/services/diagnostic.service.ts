import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export type DiagnosticStatus = 'pending' | 'analyzed' | 'validated' | 'rejected';

export interface DiagnosticAiResult {
  label: string;
  confidence: number;
  suggestedSymptoms: string[];
  recommendations: string;
}

export interface DiagnosticBiometricsHistogram {
  r: number[];
  g: number[];
  b: number[];
}

/**
 * Toujours fourni par le backend (analyse Sharp côté serveur) — pas de `?`
 * sur les champs lus par le template du studio d'analyse, sinon Angular
 * strict templates refuse l'expression `biometrics.blurScore * 100`.
 */
export interface DiagnosticBiometrics {
  blurScore: number;
  chlorosisRatio: number;
  necrosisRatio: number;
  histogram: DiagnosticBiometricsHistogram;
}

export interface DiagnosticRequest {
  id: string;
  parcelId: string;
  ownerName: string;
  ownerPhone: string;
  photoUrl: string | null;
  status: DiagnosticStatus;
  createdAt: string;
  aiResult?: DiagnosticAiResult;
  // Trace de facturation wallet (cf. backend commit e6beb08)
  userId?: string;
  feeAmount?: number;
  feeReference?: string;
}

@Injectable({ providedIn: 'root' })
export class DiagnosticService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/diagnostics`;

  getAll(): Observable<DiagnosticRequest[]> {
    return this.http.get<DiagnosticRequest[]>(this.apiUrl).pipe(
      map((requests) =>
        requests.map((req) => ({
          ...req,
          photoUrl: req.photoUrl
            ? req.photoUrl.startsWith('http')
              ? req.photoUrl
              : `${environment.apiUrl}/${req.photoUrl}`
            : null,
        })),
      ),
    );
  }

  validate(id: string, approve: boolean, comment: string): Observable<DiagnosticRequest> {
    return this.http.patch<DiagnosticRequest>(`${this.apiUrl}/${id}/validate`, {
      approve,
      comment,
    });
  }

  getStats(): Observable<unknown> {
    return this.http.get(`${this.apiUrl}/stats`);
  }

  getBiometrics(id: string): Observable<DiagnosticBiometrics> {
    return this.http.get<DiagnosticBiometrics>(`${this.apiUrl}/${id}/biometrics`);
  }
}
