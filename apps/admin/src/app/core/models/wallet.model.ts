/**
 * Modèles partagés autour du wallet technicien.
 * Le backend renvoie le solde mis à jour après chaque opération admin.
 */

export type WalletAdminOperation = 'RECHARGE' | 'AJUSTEMENT' | 'REGULATION';

export interface WalletAdminTransactionResponse {
  id: string;
  userId: string;
  amount: number;
  type: 'CREDIT' | 'DEBIT';
  newBalance: number;
  createdAt: string;
}

/**
 * Mapping renvoyé par GET /parcels (raw shape).
 * Utilisé en interne par ParcelService pour traduire vers Parcel.
 */
export interface ParcelApiPayload {
  id: string;
  name?: string;
  owner?: string;
  ownerName?: string;
  ownerId?: string;
  phone?: string;
  ownerPhone?: string;
  village?: string;
  technician?: string;
  technicianName?: string;
  crop?: string;
  cropType?: string;
  healthScore?: number;
  estimatedYield?: number;
  area?: number;
  status?: string;
  location?: { lat: number; lng: number; region?: string };
  boundary?: { type: string; coordinates: number[][][] };
  createdAt?: string;
}

/**
 * Payload envoyé à POST/PATCH /parcels — exhaustif pour pouvoir
 * activer le strict TypeScript sans casser ParcelService.
 */
export interface ParcelMutationPayload {
  id?: string;
  name?: string;
  owner?: string;
  phone?: string;
  village?: string;
  technician?: string;
  crop?: string;
  estimatedYield?: number;
  healthScore?: number;
  lastVisit?: string;
  boundary?: { type: string; coordinates: number[][][] };
}
