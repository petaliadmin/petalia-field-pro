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
  templateUrl: './users.component.html',
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
