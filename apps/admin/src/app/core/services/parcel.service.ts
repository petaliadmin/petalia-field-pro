import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Parcel {
  id: string;
  ownerId: string;
  ownerName: string;
  ownerPhone?: string;
  area?: number;
  location?: { lat: number; lng: number; region?: string };
  status: 'healthy' | 'water_stress' | 'infection' | 'unknown';
  cropType?: string;
  createdAt: string;
}

@Injectable({ providedIn: 'root' })
export class ParcelService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/parcels`;

  getAll(): Observable<Parcel[]> {
    return this.http.get<any>(this.apiUrl).pipe(
      map(res => Array.isArray(res) ? res : (res?.data || []))
    );
  }

  create(parcel: Partial<Parcel>): Observable<Parcel> {
    return this.http.post<Parcel>(this.apiUrl, parcel);
  }

  update(id: string, parcel: Partial<Parcel>): Observable<Parcel> {
    return this.http.patch<Parcel>(`${this.apiUrl}/${id}`, parcel);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
