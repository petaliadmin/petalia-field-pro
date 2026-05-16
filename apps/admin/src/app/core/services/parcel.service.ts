import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Parcel {
  id: string;
  ownerId: string;
  ownerName: string;
  ownerPhone?: string;
  technician?: string;
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
      map(res => {
        const list = Array.isArray(res) ? res : (res?.data || []);
        return list.map((item: any) => ({
          ...item,
          id: item.id,
          ownerId: item.ownerId || item.id,
          ownerName: item.ownerName || item.owner || item.name || 'Producteur inconnu',
          ownerPhone: item.ownerPhone || item.phone || '',
          technician: item.technician || item.technicianName || 'Non affecté',
          area: item.area || item.estimatedYield || 1.5,
          location: item.location || { lat: 16.033, lng: -16.483, region: item.village || 'Saint-Louis' },
          status: item.status || (item.healthScore >= 80 ? 'healthy' : item.healthScore >= 50 ? 'water_stress' : 'infection'),
          cropType: item.cropType || item.crop || 'Non spécifié',
          createdAt: item.createdAt || new Date().toISOString()
        }));
      })
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
