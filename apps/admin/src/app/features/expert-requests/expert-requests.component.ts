import { Component, OnInit, inject, ChangeDetectionStrategy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { takeUntil } from 'rxjs';
import { ExpertRequestsService, ExpertRequestItem } from '../../core/services/expert-requests.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';
import { trackById } from '../../core/utils/track-by';
import { BaseComponent } from '../../core/base/base.component';

@Component({
  selector: 'app-expert-requests',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, LucideAngularModule, FormsModule],
  templateUrl: './expert-requests.component.html',
  styles: [`:host { display: block; }`]
})
export class ExpertRequestsComponent extends BaseComponent implements OnInit {
  readonly trackById = trackById;
  requests: ExpertRequestItem[] = [];
  selectedRequest: ExpertRequestItem | null = null;
  expertAdvice = '';
  searchQuery = '';
  statusFilter = '';
  isLoading = false;

  private requestsService = inject(ExpertRequestsService);
  private alertService = inject(AlertConfirmService);
  private cdr = inject(ChangeDetectorRef);

  ngOnInit() {
    this.loadRequests();
  }

  loadRequests() {
    this.isLoading = true;
    this.requestsService.getAllRequests().pipe(takeUntil(this.destroy$)).subscribe({
      next: (data) => {
        this.requests = data;
        this.isLoading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.requests = [];
        this.isLoading = false;
        this.cdr.markForCheck();
      },
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
        this.requestsService.respond(this.selectedRequest.id, this.expertAdvice, status)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
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
              this.cdr.markForCheck();
            },
            error: () => {},
          });
      }
    });
  }
}
