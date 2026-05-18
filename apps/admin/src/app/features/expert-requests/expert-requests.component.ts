import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { ExpertRequestsService, ExpertRequestItem } from '../../core/services/expert-requests.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';

@Component({
  selector: 'app-expert-requests',
  standalone: true,
  imports: [CommonModule, LucideAngularModule, FormsModule],
  templateUrl: './expert-requests.component.html',
  styles: [`
    :host { display: block; }
  `]
})
export class ExpertRequestsComponent implements OnInit {
  requests: ExpertRequestItem[] = [];
  selectedRequest: ExpertRequestItem | null = null;
  expertAdvice: string = '';
  searchQuery = '';
  statusFilter = '';

  private requestsService = inject(ExpertRequestsService);
  private alertService = inject(AlertConfirmService);

  ngOnInit() {
    this.loadRequests();
  }

  loadRequests() {
    this.requestsService.getAllRequests().subscribe({
      next: (data) => (this.requests = data),
      error: () => (this.requests = []),
    });
  }

  selectRequest(req: ExpertRequestItem) {
    this.selectedRequest = req;
    this.expertAdvice = req.expertAdvice ?? '';
  }

  get filteredRequests(): ExpertRequestItem[] {
    return this.requests.filter(r => {
      const matchesSearch = !this.searchQuery || 
        (r.parcel?.owner || '').toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        (r.parcel?.name || '').toLowerCase().includes(this.searchQuery.toLowerCase());
      const matchesStatus = !this.statusFilter || r.status === this.statusFilter;
      return matchesSearch && matchesStatus;
    });
  }

  respond(status: 'completed' | 'cancelled') {
    if (!this.selectedRequest) return;
    
    const action = status === 'completed' ? 'envoyer cet avis expert' : 'annuler cette demande';
    this.alertService.confirm({
      title: `${status === 'completed' ? 'Envoi' : 'Annulation'} de l'avis expert`,
      message: `Voulez-vous vraiment ${action} pour la parcelle ${this.selectedRequest.parcel?.name} de ${this.selectedRequest.parcel?.owner} ?`,
      confirmText: status === 'completed' ? 'ENVOYER' : 'ANNULER',
      confirmButtonColor: status === 'completed' ? 'bg-primary hover:bg-primary-dark shadow-primary/20' : 'bg-red-600 hover:bg-red-700 shadow-red-600/20',
      onConfirm: () => {
        if (!this.selectedRequest) return;
        this.requestsService.respond(this.selectedRequest.id, this.expertAdvice, status).subscribe({
          next: (updated) => {
            const refundNote =
              status === 'cancelled' && updated.feeAmount
                ? ` ${updated.feeAmount} XOF ont été remboursés au technicien.`
                : '';
            this.alertService.success(
              `L'avis expert a été ${status === 'completed' ? 'envoyé' : 'annulé'} avec succès.${refundNote}`,
            );
            this.loadRequests();
            this.selectedRequest = null;
            this.expertAdvice = '';
          },
          error: () => {},
        });
      }
    });
  }
}
