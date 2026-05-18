import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { UserService, UserAccount } from '../../core/services/user.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [CommonModule, LucideAngularModule, FormsModule],
  template: `
    <div class="space-y-6">
      <div class="flex justify-between items-end">
        <div>
          <h2 class="text-2xl font-black text-slate-900 tracking-tight">Gestion des Comptes & Portefeuilles</h2>
          <p class="text-slate-500 font-medium">Gérez les comptes utilisateurs, rechargez les portefeuilles et effectuez des régulations</p>
        </div>
        
        <button (click)="openCreateModal()" class="flex items-center gap-2 px-6 py-3 bg-primary text-white rounded-2xl font-black text-sm shadow-xl shadow-primary/20 hover:bg-primary-dark transition-all">
          <lucide-icon name="user-plus" class="w-5 h-5"></lucide-icon>
          Nouvel Utilisateur
        </button>
      </div>

      <!-- Filters & Search -->
      <div class="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex items-center justify-between gap-4">
        <div class="flex-1 relative">
          <lucide-icon name="search" class="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-slate-400"></lucide-icon>
          <input [(ngModel)]="searchQuery" type="text" placeholder="Rechercher par nom, email ou rôle..." class="w-full pl-12 pr-4 py-3 bg-gray-50 border border-transparent rounded-xl text-sm focus:bg-white focus:border-primary/20 outline-none transition-all">
        </div>
        
        <div class="flex items-center gap-2">
          <select [(ngModel)]="roleFilter" class="px-4 py-3 bg-gray-50 text-slate-600 rounded-xl text-sm font-bold border-none outline-none focus:ring-2 focus:ring-primary/20">
            <option value="">Tous les Rôles</option>
            <option value="ADMIN">Administrateur</option>
            <option value="EXPERT">Expert</option>
            <option value="TECHNICIAN">Technicien</option>
          </select>

          <select [(ngModel)]="statusFilter" class="px-4 py-3 bg-gray-50 text-slate-600 rounded-xl text-sm font-bold border-none outline-none focus:ring-2 focus:ring-primary/20">
            <option value="">Tous les Statuts</option>
            <option value="ACTIVE">Actif</option>
            <option value="INACTIVE">Inactif</option>
          </select>
        </div>
      </div>

      <!-- Empty State -->
      <div *ngIf="filteredUsers.length === 0" class="bg-white rounded-2xl p-12 text-center border-2 border-dashed border-gray-200">
        <lucide-icon name="users" class="w-12 h-12 text-slate-300 mx-auto mb-4"></lucide-icon>
        <p class="text-slate-500 font-bold">Aucun utilisateur trouvé</p>
      </div>

      <!-- Users Grid -->
      <div class="grid grid-cols-3 gap-6">
        <div *ngFor="let user of filteredUsers" class="bg-white rounded-[32px] p-6 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all group relative overflow-hidden">
          <!-- Status Badge -->
          <div class="absolute top-6 right-6">
            <span [ngClass]="user.status === 'ACTIVE' ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'" class="text-[10px] font-black px-2 py-1 rounded-lg">
              {{ user.status }}
            </span>
          </div>

          <!-- Profile Header -->
          <div class="flex items-center gap-4 mb-6">
            <div class="w-16 h-16 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400 border border-slate-200">
              <lucide-icon name="user" class="w-8 h-8"></lucide-icon>
            </div>
            <div>
              <h3 class="font-black text-slate-900 leading-tight">{{ user.name }}</h3>
              <div class="flex items-center gap-1 mt-1">
                <lucide-icon name="shield" class="w-3 h-3 text-primary"></lucide-icon>
                <span class="text-xs font-bold text-primary">{{ user.role }}</span>
              </div>
            </div>
          </div>

          <!-- Contact Info -->
          <div class="space-y-3 mb-6">
            <div class="flex items-center gap-3 text-slate-500">
              <lucide-icon name="mail" class="w-4 h-4"></lucide-icon>
              <span class="text-sm font-medium">{{ user.email }}</span>
            </div>
            <div class="flex items-center gap-3 text-slate-500">
              <lucide-icon name="smartphone" class="w-4 h-4"></lucide-icon>
              <span class="text-sm font-medium">{{ user.phone || 'Non renseigné' }}</span>
            </div>
          </div>

          <!-- Wallet Balance Badge -->
          <div class="mb-6 p-4 bg-amber-50 rounded-2xl border border-amber-100 flex items-center justify-between">
            <div class="flex items-center gap-2">
              <lucide-icon name="coins" class="w-5 h-5 text-amber-600"></lucide-icon>
              <span class="text-xs font-bold text-amber-900 uppercase tracking-wider">Solde Crédits</span>
            </div>
            <span class="text-base font-black text-amber-700">{{ user.walletBalance || 0 }} CRÉDITS</span>
          </div>

          <!-- Actions -->
          <div class="flex gap-2 pt-4 border-t border-gray-50">
            <button (click)="openWalletModal(user)" class="flex-1 py-3 bg-amber-500 text-white rounded-xl text-xs font-black hover:bg-amber-600 transition-all shadow-lg shadow-amber-500/20 flex items-center justify-center gap-1">
              <lucide-icon name="wallet" class="w-4 h-4"></lucide-icon>
              PORTEFEUILLE
            </button>
            <button (click)="openEditModal(user)" class="px-4 py-3 bg-gray-50 text-slate-700 rounded-xl text-xs font-black hover:bg-gray-100 transition-all">MODIFIER</button>
            <button (click)="toggleStatus(user)" class="px-4 py-3 bg-gray-50 text-red-600 rounded-xl hover:bg-red-50 transition-all">
              <lucide-icon [name]="user.status === 'ACTIVE' ? 'circle-x' : 'circle-check-big'" class="w-5 h-5"></lucide-icon>
            </button>
          </div>

          <!-- Abstract background shape -->
          <div class="absolute -bottom-4 -right-4 w-24 h-24 bg-primary/5 rounded-full blur-2xl group-hover:bg-primary/10 transition-colors"></div>
        </div>
      </div>

      <!-- User Creation/Edit Modal -->
      <div *ngIf="showUserModal" class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in">
        <div class="bg-white rounded-[32px] p-8 max-w-lg w-full shadow-2xl border border-gray-100 relative overflow-hidden">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-xl font-black text-slate-900">{{ isEditing ? 'Modifier Utilisateur' : 'Nouvel Utilisateur' }}</h3>
            <button (click)="closeUserModal()" class="p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-50 transition-all">
              <lucide-icon name="x" class="w-6 h-6"></lucide-icon>
            </button>
          </div>

          <div class="space-y-4 mb-8">
            <div>
              <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Nom complet *</label>
              <input [(ngModel)]="currentUser.name" type="text" placeholder="Ex: Amadou Bah" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
            </div>

            <div>
              <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Email *</label>
              <input [(ngModel)]="currentUser.email" type="email" placeholder="Ex: amadou@petalia.ag" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
            </div>

            <div>
              <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Téléphone</label>
              <input [(ngModel)]="currentUser.phone" type="text" placeholder="Ex: +221771234567" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Rôle *</label>
                <select [(ngModel)]="currentUser.role" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
                  <option value="TECHNICIAN">Technicien</option>
                  <option value="EXPERT">Expert</option>
                  <option value="ADMIN">Administrateur</option>
                </select>
              </div>

              <div>
                <label class="text-xs font-bold text-slate-700 uppercase tracking-wider block mb-2">Statut *</label>
                <select [(ngModel)]="currentUser.status" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
                  <option value="ACTIVE">Actif</option>
                  <option value="INACTIVE">Inactif</option>
                </select>
              </div>
            </div>
          </div>

          <div class="flex gap-4 shrink-0 mt-6">
            <button (click)="closeUserModal()" class="flex-1 py-4 bg-gray-100 text-slate-700 rounded-2xl font-black text-sm hover:bg-gray-200 transition-all">
              ANNULER
            </button>
            <button (click)="saveUser()" class="flex-1 py-4 bg-primary text-white rounded-2xl font-black text-sm shadow-xl shadow-primary/20 hover:bg-primary-dark transition-all flex items-center justify-center gap-2">
              <lucide-icon name="check" class="w-5 h-5"></lucide-icon>
              {{ isEditing ? 'ENREGISTRER' : 'CRÉER' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Wallet Modal -->
      <div *ngIf="selectedUser" class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in">
        <div class="bg-white rounded-[32px] p-8 max-w-lg w-full shadow-2xl border border-gray-100 relative overflow-hidden">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-xl font-black text-slate-900">Gestion du Portefeuille</h3>
              <p class="text-sm text-slate-500 font-medium">Compte de {{ selectedUser.name }}</p>
            </div>
            <button (click)="closeWalletModal()" class="p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-50 transition-all">
              <lucide-icon name="x" class="w-6 h-6"></lucide-icon>
            </button>
          </div>

          <!-- Current Balance -->
          <div class="bg-amber-50 p-6 rounded-2xl border border-amber-100 mb-6 flex items-center justify-between">
            <div>
              <span class="text-xs font-bold text-amber-800 uppercase tracking-wider">Solde Actuel</span>
              <div class="text-2xl font-black text-amber-900 mt-1">{{ selectedUser.walletBalance || 0 }} CRÉDITS</div>
            </div>
            <div class="w-12 h-12 rounded-2xl bg-amber-100 flex items-center justify-center text-amber-600">
              <lucide-icon name="coins" class="w-6 h-6"></lucide-icon>
            </div>
          </div>

          <!-- Operation Type Selection -->
          <div class="grid grid-cols-3 gap-3 mb-6">
            <button (click)="walletOp.type = 'RECHARGE'" [ngClass]="walletOp.type === 'RECHARGE' ? 'bg-emerald-500 text-white shadow-lg shadow-emerald-500/20' : 'bg-gray-50 text-slate-600 hover:bg-gray-100'" class="p-4 rounded-2xl font-black text-xs transition-all flex flex-col items-center gap-2">
              <lucide-icon name="arrow-up-circle" class="w-5 h-5"></lucide-icon>
              RECHARGE
            </button>
            <button (click)="walletOp.type = 'AJUSTEMENT'" [ngClass]="walletOp.type === 'AJUSTEMENT' ? 'bg-blue-500 text-white shadow-lg shadow-blue-500/20' : 'bg-gray-50 text-slate-600 hover:bg-gray-100'" class="p-4 rounded-2xl font-black text-xs transition-all flex flex-col items-center gap-2">
              <lucide-icon name="sliders" class="w-5 h-5"></lucide-icon>
              AJUSTEMENT
            </button>
            <button (click)="walletOp.type = 'REGULATION'" [ngClass]="walletOp.type === 'REGULATION' ? 'bg-red-500 text-white shadow-lg shadow-red-500/20' : 'bg-gray-50 text-slate-600 hover:bg-gray-100'" class="p-4 rounded-2xl font-black text-xs transition-all flex flex-col items-center gap-2">
              <lucide-icon name="scale" class="w-5 h-5"></lucide-icon>
              RÉGULATION
            </button>
          </div>

          <!-- Amount Input -->
          <div class="mb-6 space-y-2">
            <label class="text-xs font-bold text-slate-700 uppercase tracking-wider">Montant (Crédits)</label>
            <div class="relative">
              <input [(ngModel)]="walletOp.amount" type="number" placeholder="Ex: 50" class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl text-sm font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all">
              <span class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400 uppercase">CRÉDITS</span>
            </div>
            <p *ngIf="walletOp.type === 'AJUSTEMENT'" class="text-[11px] text-slate-500 italic">Astuce: Utilisez un montant négatif (ex: -1000) pour un ajustement en retrait.</p>
          </div>

          <!-- Description Input -->
          <div class="mb-8 space-y-2">
            <label class="text-xs font-bold text-slate-700 uppercase tracking-wider">Motif obligatoire</label>
            <textarea [(ngModel)]="walletOp.description" rows="3" placeholder="Indiquez la raison de cette opération administrative..." class="w-full p-4 bg-gray-50 border border-gray-200 rounded-xl text-sm text-slate-900 focus:bg-white focus:border-primary/20 outline-none transition-all"></textarea>
          </div>

          <!-- Submit Button -->
          <div class="flex gap-4 shrink-0 mt-6">
            <button (click)="closeWalletModal()" class="flex-1 py-4 bg-gray-100 text-slate-700 rounded-2xl font-black text-sm hover:bg-gray-200 transition-all">
              ANNULER
            </button>
            <button (click)="submitWalletOperation()" [disabled]="isLoading" class="flex-1 py-4 bg-primary text-white rounded-2xl font-black text-sm shadow-xl shadow-primary/20 hover:bg-primary-dark transition-all disabled:opacity-50 flex items-center justify-center gap-2">
              <lucide-icon *ngIf="isLoading" name="loader-2" class="w-5 h-5 animate-spin"></lucide-icon>
              CONFIRMER
            </button>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class UsersComponent implements OnInit {
  users: UserAccount[] = [];
  selectedUser: UserAccount | null = null;
  isLoading = false;
  searchQuery = '';
  roleFilter = '';
  statusFilter = '';

  showUserModal = false;
  isEditing = false;
  currentUser: Partial<UserAccount> = {
    name: '',
    email: '',
    role: 'TECHNICIAN',
    status: 'ACTIVE',
    phone: ''
  };

  walletOp: {
    type: 'RECHARGE' | 'AJUSTEMENT' | 'REGULATION';
    amount: number;
    description: string;
  } = {
    type: 'RECHARGE',
    amount: 0,
    description: '',
  };

  private userService = inject(UserService);
  private alertService = inject(AlertConfirmService);

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    // L'errorInterceptor signale les erreurs HTTP ; on garde un fallback silencieux.
    this.userService.getUsersWithBalance().subscribe({
      next: (data) => (this.users = data),
      error: () => (this.users = []),
    });
  }

  get filteredUsers(): UserAccount[] {
    return this.users.filter(u => {
      const matchesSearch = !this.searchQuery || 
        u.name.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        u.email.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        u.role.toLowerCase().includes(this.searchQuery.toLowerCase());
      const matchesRole = !this.roleFilter || u.role === this.roleFilter;
      const matchesStatus = !this.statusFilter || u.status === this.statusFilter;
      return matchesSearch && matchesRole && matchesStatus;
    });
  }

  openCreateModal() {
    this.isEditing = false;
    this.currentUser = { name: '', email: '', role: 'TECHNICIAN', status: 'ACTIVE', phone: '' };
    this.showUserModal = true;
  }

  openEditModal(user: UserAccount) {
    this.isEditing = true;
    this.currentUser = { ...user };
    this.showUserModal = true;
  }

  closeUserModal() {
    this.showUserModal = false;
  }

  saveUser() {
    if (!this.currentUser.name || !this.currentUser.email) {
      this.alertService.warning('Veuillez remplir les champs obligatoires (Nom et Email)');
      return;
    }

    if (this.isEditing && this.currentUser.id) {
      this.userService.update(this.currentUser.id, this.currentUser).subscribe({
        next: () => {
          this.alertService.success('Utilisateur modifié avec succès');
          this.loadUsers();
          this.closeUserModal();
        },
        error: (err) => this.alertService.error('Erreur lors de la modification : ' + err.message)
      });
    } else {
      this.userService.create(this.currentUser).subscribe({
        next: () => {
          this.alertService.success('Utilisateur créé avec succès');
          this.loadUsers();
          this.closeUserModal();
        },
        error: (err) => this.alertService.error('Erreur lors de la création : ' + err.message)
      });
    }
  }

  openWalletModal(user: UserAccount) {
    this.selectedUser = user;
    this.walletOp = {
      type: 'RECHARGE',
      amount: 0,
      description: '',
    };
  }

  closeWalletModal() {
    this.selectedUser = null;
  }

  submitWalletOperation() {
    if (!this.selectedUser) return;
    if (!this.walletOp.amount) {
      this.alertService.warning('Veuillez entrer un montant valide');
      return;
    }
    if (!this.walletOp.description.trim()) {
      this.alertService.warning('Veuillez indiquer un motif obligatoire');
      return;
    }

    this.isLoading = true;
    this.userService.performWalletOperation(
      this.selectedUser.id,
      this.walletOp.type,
      this.walletOp.amount,
      this.walletOp.description,
    ).subscribe({
      next: (res) => {
        this.isLoading = false;
        this.alertService.success(`Opération réussie ! Nouveau solde : ${res.newBalance} CRÉDITS`);
        this.closeWalletModal();
        this.loadUsers();
      },
      error: (err) => {
        this.isLoading = false;
        this.alertService.error('Erreur lors de l\'opération : ' + (err.error?.message || err.message));
      }
    });
  }

  toggleStatus(user: UserAccount) {
    const action = user.status === 'ACTIVE' ? 'désactiver' : 'activer';
    this.alertService.confirm({
      title: `${action === 'désactiver' ? 'Désactivation' : 'Activation'} du compte`,
      message: `Voulez-vous vraiment ${action} le compte de ${user.name} ?`,
      confirmText: action.toUpperCase(),
      confirmButtonColor: user.status === 'ACTIVE' ? 'bg-amber-500 hover:bg-amber-600 shadow-amber-500/20' : 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-600/20',
      onConfirm: () => {
        const newStatus = user.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
        this.userService.update(user.id, { status: newStatus as any }).subscribe({
          next: () => {
            this.alertService.success(`Le compte de ${user.name} a été ${action === 'désactiver' ? 'désactivé' : 'activé'} avec succès.`);
            this.loadUsers();
          },
          error: (err) => this.alertService.error('Erreur: ' + err.message)
        });
      }
    });
  }
}
