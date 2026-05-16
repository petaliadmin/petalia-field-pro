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
    return this.http.get<any>(`${this.apiUrl}?limit=1000`).pipe(
      map(res => {
        const list = Array.isArray(res) ? res : (res?.data || []);
        return list.map((item: any) => {
          let lat = 16.033;
          let lng = -16.483;
          if (item.boundary?.coordinates?.[0]?.[0]) {
            lng = item.boundary.coordinates[0][0][0];
            lat = item.boundary.coordinates[0][0][1];
          }
          return {
            ...item,
            id: item.id,
            ownerId: item.ownerId || item.id,
            ownerName: item.owner || item.ownerName || item.name || 'Producteur inconnu',
            ownerPhone: item.phone || item.ownerPhone || '',
            technician: item.technician || item.technicianName || 'Non affecté',
            area: item.estimatedYield || item.area || 1.5,
            location: item.location || { lat, lng, region: item.village || item.location?.region || 'Saint-Louis' },
            status: item.status || (item.healthScore >= 80 ? 'healthy' : item.healthScore >= 50 ? 'water_stress' : 'infection'),
            cropType: item.crop || item.cropType || 'Non spécifié',
            createdAt: item.createdAt || new Date().toISOString()
          };
        });
      })
    );
  }

  create(parcel: Partial<Parcel>): Observable<Parcel> {
    const parcelId = parcel.id || crypto.randomUUID();
    const payload = {
      id: parcelId,
      name: `PAR-${Math.floor(Math.random() * 10000)}`,
      owner: parcel.ownerName || 'Producteur inconnu',
      phone: parcel.ownerPhone || '',
      crop: parcel.cropType || 'Non spécifié',
      estimatedYield: parcel.area || 1.5,
      village: parcel.location?.region || 'Sénégal',
      technician: parcel.technician || 'Non affecté',
      lastVisit: new Date().toISOString(),
      boundary: {
        type: 'Polygon',
        coordinates: [[[ -16.483, 16.033 ], [ -16.483, 16.043 ], [ -16.473, 16.043 ], [ -16.473, 16.033 ], [ -16.483, 16.033 ]]]
      }
    };
    return this.http.post<Parcel>(this.apiUrl, payload);
  }

  update(id: string, parcel: Partial<Parcel>): Observable<Parcel> {
    const payload: any = {};
    if (parcel.ownerName !== undefined) payload.owner = parcel.ownerName;
    if (parcel.ownerPhone !== undefined) payload.phone = parcel.ownerPhone;
    if (parcel.cropType !== undefined) payload.crop = parcel.cropType;
    if (parcel.area !== undefined) payload.estimatedYield = parcel.area;
    if (parcel.location?.region !== undefined) payload.village = parcel.location.region;
    if (parcel.technician !== undefined) payload.technician = parcel.technician;
    if (parcel.status !== undefined) {
      payload.healthScore = parcel.status === 'healthy' ? 90 : parcel.status === 'water_stress' ? 60 : 30;
    }
    return this.http.patch<Parcel>(`${this.apiUrl}/${id}`, payload);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
