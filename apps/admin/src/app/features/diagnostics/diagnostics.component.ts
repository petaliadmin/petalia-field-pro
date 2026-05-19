import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { takeUntil } from 'rxjs';
import { DiagnosticService, DiagnosticRequest } from '../../core/services/diagnostic.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';
import { AdvancedImageAnalyzerComponent } from '../../components/advanced-image-analyzer/advanced-image-analyzer.component';
import { trackById } from '../../core/utils/track-by';
import { BaseComponent } from '../../core/base/base.component';

@Component({
  selector: 'app-diagnostics',
  standalone: true,
  imports: [CommonModule, LucideAngularModule, FormsModule, AdvancedImageAnalyzerComponent],
  templateUrl: './diagnostics.component.html',
  styles: [`:host { display: block; }`]
})
export class DiagnosticsComponent extends BaseComponent implements OnInit {
  readonly trackById = trackById;
  diagnostics: DiagnosticRequest[] = [];
  selectedRequest: DiagnosticRequest | null = null;
  adminComment = '';
  searchQuery = '';
  statusFilter = '';
  showAnalyzer = false;
  isLoading = false;

  private diagnosticService = inject(DiagnosticService);
  private alertService = inject(AlertConfirmService);
  private cdr = inject(ChangeDetectorRef);

  ngOnInit() {
    this.loadDiagnostics();
  }

  loadDiagnostics() {
    this.isLoading = true;
    this.diagnosticService.getAll().pipe(takeUntil(this.destroy$)).subscribe({
      next: (data) => {
        this.diagnostics = data;
        this.isLoading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.diagnostics = [];
        this.isLoading = false;
        this.cdr.markForCheck();
      },
    });
  }

  get filteredDiagnostics(): DiagnosticRequest[] {
    return this.diagnostics.filter(d => {
      const matchesSearch = !this.searchQuery ||
        d.ownerName.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        d.parcelId.toLowerCase().includes(this.searchQuery.toLowerCase());
      const matchesStatus = !this.statusFilter || d.status === this.statusFilter;
      return matchesSearch && matchesStatus;
    });
  }

  validate(approve: boolean) {
    if (!this.selectedRequest) return;

    const action = approve ? 'valider' : 'rejeter';
    this.alertService.confirm({
      title: `${approve ? 'Validation' : 'Rejet'} du diagnostic`,
      message: `Voulez-vous vraiment ${action} le diagnostic pour la parcelle #${this.selectedRequest.parcelId.split('-')[0]} de ${this.selectedRequest.ownerName} ?`,
      confirmText: action.toUpperCase(),
      confirmButtonColor: approve ? 'bg-primary hover:bg-primary-dark shadow-primary/20' : 'bg-red-600 hover:bg-red-700 shadow-red-600/20',
      onConfirm: () => {
        if (!this.selectedRequest) return;
        this.diagnosticService.validate(this.selectedRequest.id, approve, this.adminComment)
          .pipe(takeUntil(this.destroy$))
          .subscribe({
            next: (updated) => {
              const refundNote =
                !approve && updated.feeAmount
                  ? ` ${updated.feeAmount} XOF ont été remboursés au technicien.`
                  : '';
              this.alertService.success(
                `Le diagnostic a été ${approve ? 'validé' : 'rejeté'} avec succès.${refundNote}`,
              );
              this.loadDiagnostics();
              this.selectedRequest = null;
              this.adminComment = '';
              this.cdr.markForCheck();
            },
            error: () => {},
          });
      }
    });
  }

  onImgError(event: Event) {
    (event.target as HTMLImageElement).src =
      'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 24 24" fill="none" stroke="%23cbd5e1" stroke-width="1.5"%3E%3Crect x="3" y="3" width="18" height="18" rx="2"/%3E%3Ccircle cx="8.5" cy="8.5" r="1.5"/%3E%3Cpath d="M21 15l-5-5L5 21"/%3E%3C/svg%3E';
  }
}
