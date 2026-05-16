import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

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

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private apiUrl = 'http://localhost:3000/users';
  private walletAdminUrl = 'http://localhost:3000/wallet/admin';

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

  performWalletOperation(userId: string, operationType: 'RECHARGE' | 'AJUSTEMENT' | 'REGULATION', amount: number, description: string): Observable<any> {
    return this.http.post<any>(`${this.walletAdminUrl}/transactions`, {
      userId,
      operationType,
      amount,
      description,
    });
  }
}
