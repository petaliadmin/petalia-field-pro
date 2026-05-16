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
          ownerName: item.owner || item.ownerName || item.name || 'Producteur inconnu',
          ownerPhone: item.phone || item.ownerPhone || '',
          technician: item.technician || item.technicianName || 'Non affecté',
          area: item.estimatedYield || item.area || 1.5,
          location: item.location || { lat: 16.033, lng: -16.483, region: item.village || item.location?.region || 'Saint-Louis' },
          status: item.status || (item.healthScore >= 80 ? 'healthy' : item.healthScore >= 50 ? 'water_stress' : 'infection'),
          cropType: item.crop || item.cropType || 'Non spécifié',
          createdAt: item.createdAt || new Date().toISOString()
        }));
      })
    );
  }

  create(parcel: Partial<Parcel>): Observable<Parcel> {
    const payload = {
      ...parcel,
      owner: parcel.ownerName || 'Producteur inconnu',
      phone: parcel.ownerPhone || '',
      crop: parcel.cropType || 'Non spécifié',
      estimatedYield: parcel.area || 1.5,
      village: parcel.location?.region || 'Sénégal',
      name: parcel.id || `PAR-${Math.floor(Math.random() * 10000)}`,
    };
    return this.http.post<Parcel>(this.apiUrl, payload);
  }

  update(id: string, parcel: Partial<Parcel>): Observable<Parcel> {
    const payload = {
      ...parcel,
      owner: parcel.ownerName || (parcel as any)['owner'],
      phone: parcel.ownerPhone || (parcel as any)['phone'],
      crop: parcel.cropType || (parcel as any)['crop'],
      estimatedYield: parcel.area || (parcel as any)['estimatedYield'],
      village: parcel.location?.region || (parcel as any)['village'],
    };
    return this.http.patch<Parcel>(`${this.apiUrl}/${id}`, payload);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
