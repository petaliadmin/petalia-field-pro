import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ParcelApiPayload, ParcelMutationPayload } from '../models/wallet.model';
import { DEFAULT_LAT, DEFAULT_LNG } from '../constants/app.constants';

export type ParcelStatus = 'healthy' | 'water_stress' | 'infection' | 'unknown';

export interface Parcel {
  id: string;
  ownerId: string;
  ownerName: string;
  ownerPhone?: string;
  technician?: string;
  area?: number;
  location?: { lat: number; lng: number; region?: string };
  status: ParcelStatus;
  cropType?: string;
  createdAt: string;
}

interface ParcelListResponse {
  data?: ParcelApiPayload[];
  total?: number;
}


@Injectable({ providedIn: 'root' })
export class ParcelService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/parcels`;

  getAll(): Observable<Parcel[]> {
    return this.http
      .get<ParcelListResponse | ParcelApiPayload[]>(`${this.apiUrl}?limit=1000`)
      .pipe(
        map((res) => {
          const list: ParcelApiPayload[] = Array.isArray(res) ? res : res?.data ?? [];
          return list.map((item) => this.toParcel(item));
        }),
      );
  }

  create(parcel: Partial<Parcel>): Observable<Parcel> {
    const parcelId = parcel.id || crypto.randomUUID();
    const payload: ParcelMutationPayload = {
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
        coordinates: [
          [
            [-16.483, 16.033],
            [-16.483, 16.043],
            [-16.473, 16.043],
            [-16.473, 16.033],
            [-16.483, 16.033],
          ],
        ],
      },
    };
    return this.http.post<Parcel>(this.apiUrl, payload);
  }

  update(id: string, parcel: Partial<Parcel>): Observable<Parcel> {
    const payload: ParcelMutationPayload = {};
    if (parcel.ownerName !== undefined) payload.owner = parcel.ownerName;
    if (parcel.ownerPhone !== undefined) payload.phone = parcel.ownerPhone;
    if (parcel.cropType !== undefined) payload.crop = parcel.cropType;
    if (parcel.area !== undefined) payload.estimatedYield = parcel.area;
    if (parcel.location?.region !== undefined) payload.village = parcel.location.region;
    if (parcel.technician !== undefined) payload.technician = parcel.technician;
    if (parcel.status !== undefined) {
      payload.healthScore =
        parcel.status === 'healthy' ? 90 : parcel.status === 'water_stress' ? 60 : 30;
    }
    return this.http.patch<Parcel>(`${this.apiUrl}/${id}`, payload);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  /**
   * Normalisation centralisée de la forme renvoyée par le backend
   * (champs nommés indifféremment owner/ownerName, etc.). On expose
   * un type Parcel stable côté UI tout en restant tolérant aux
   * variations historiques du payload.
   */
  private toParcel(item: ParcelApiPayload): Parcel {
    let lat = DEFAULT_LAT;
    let lng = DEFAULT_LNG;
    const firstCoord = item.boundary?.coordinates?.[0]?.[0];
    if (firstCoord && firstCoord.length >= 2) {
      lng = firstCoord[0];
      lat = firstCoord[1];
    }

    const healthScore = item.healthScore ?? 0;
    const derivedStatus: ParcelStatus =
      (item.status as ParcelStatus | undefined) ??
      (healthScore >= 80 ? 'healthy' : healthScore >= 50 ? 'water_stress' : 'infection');

    return {
      id: item.id,
      ownerId: item.ownerId || item.id,
      ownerName: item.owner || item.ownerName || item.name || 'Producteur inconnu',
      ownerPhone: item.phone || item.ownerPhone || '',
      technician: item.technician || item.technicianName || 'Non affecté',
      area: item.estimatedYield || item.area || 1.5,
      location: item.location || {
        lat,
        lng,
        region: item.village || 'Saint-Louis',
      },
      status: derivedStatus,
      cropType: item.crop || item.cropType || 'Non spécifié',
      createdAt: item.createdAt || new Date().toISOString(),
    };
  }
}
