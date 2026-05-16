import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';

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
  private apiUrl = 'http://localhost:3000/parcels';

  getAll(): Observable<Parcel[]> {
    return this.http.get<any>(this.apiUrl).pipe(
      map(res => Array.isArray(res) ? res : (res?.data || []))
    );
  }
}
