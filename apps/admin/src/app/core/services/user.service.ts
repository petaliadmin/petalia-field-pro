import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  WalletAdminOperation,
  WalletAdminTransactionResponse,
} from '../models/wallet.model';

export interface UserAccount {
  id: string;
  name: string;
  email: string;
  role: 'ADMIN' | 'EXPERT' | 'TECHNICIAN';
  status: 'ACTIVE' | 'INACTIVE';
  phone?: string;
  createdAt: string;
  walletBalance?: number;
}

interface WalletAdminApiResponse {
  transaction: WalletAdminTransactionResponse;
  newBalance: number;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/users`;
  private walletAdminUrl = `${environment.apiUrl}/wallet/admin`;

  getAll(): Observable<UserAccount[]> {
    return this.http.get<UserAccount[]>(this.apiUrl);
  }

  getUsersWithBalance(): Observable<UserAccount[]> {
    return this.http.get<UserAccount[]>(`${this.walletAdminUrl}/users`);
  }

  create(user: Partial<UserAccount>): Observable<UserAccount> {
    return this.http.post<UserAccount>(this.apiUrl, user);
  }

  update(id: string, user: Partial<UserAccount>): Observable<UserAccount> {
    return this.http.patch<UserAccount>(`${this.apiUrl}/${id}`, user);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  performWalletOperation(
    userId: string,
    operationType: WalletAdminOperation,
    amount: number,
    description: string,
  ): Observable<WalletAdminApiResponse> {
    return this.http.post<WalletAdminApiResponse>(`${this.walletAdminUrl}/transactions`, {
      userId,
      operationType,
      amount,
      description,
    });
  }
}
