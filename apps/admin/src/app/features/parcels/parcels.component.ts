import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { ParcelService, Parcel } from '../../core/services/parcel.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';
import { environment } from '../../../environments/environment';
import { AdvancedImageAnalyzerComponent } from '../../components/advanced-image-analyzer/advanced-image-analyzer.component';

@Component({
  selector: 'app-parcels',
  standalone: true,
  imports: [CommonModule, FormsModule, LucideAngularModule, AdvancedImageAnalyzerComponent],
  templateUrl: './parcels.component.html',
  styles: [`:host { display: block; }`]
})
export class ParcelsComponent implements OnInit {
  parcels: Parcel[] = [];
  loading = true;
  searchQuery = '';
  statusFilter = '';
  showAnalyzer = false;

  showParcelModal = false;
  isEditing = false;
  currentParcel: Partial<Parcel> = {
    ownerName: '',
    ownerPhone: '',
    cropType: '',
    area: 1,
    status: 'healthy',
  };
  regionInput = '';

  selectedParcelDetails: Parcel | null = null;

  showAssignModal = false;
  assignParcel: Parcel | null = null;
  assignTechnicianInput = '';

  private parcelService = inject(ParcelService);
  private alertService = inject(AlertConfirmService);
  private cdr = inject(ChangeDetectorRef);

  ngOnInit() {
    this.loadParcels();
  }

  loadParcels() {
    this.loading = true;
    this.cdr.detectChanges();
    this.parcelService.getAll().subscribe({
      next: (data) => {
        this.parcels = data;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  get filteredParcels(): Parcel[] {
    return this.parcels.filter(p => {
      const matchesSearch = !this.searchQuery ||
        p.ownerName.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        p.id.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        (p.location?.region ?? '').toLowerCase().includes(this.searchQuery.toLowerCase());
      const matchesStatus = !this.statusFilter || p.status === this.statusFilter;
      return matchesSearch && matchesStatus;
    });
  }

  countByStatus(status: Parcel['status']): number {
    return this.parcels.filter(p => p.status === status).length;
  }

  statusLabel(status: Parcel['status']): string {
    const labels: Record<Parcel['status'], string> = {
      healthy: 'Sain',
      water_stress: 'Stress Hydrique',
      infection: 'Infection',
      unknown: 'Inconnu'
    };
    return labels[status];
  }

  openPassport(id: string) {
    window.open(`${environment.apiUrl}/parcels/passport/` + id, '_blank');
  }

  openCreateModal() {
    this.isEditing = false;
    this.currentParcel = { ownerName: '', ownerPhone: '', cropType: '', area: 1, status: 'healthy' };
    this.regionInput = '';
    this.showParcelModal = true;
  }

  openEditModal(parcel: Parcel) {
    this.isEditing = true;
    this.currentParcel = { ...parcel };
    this.regionInput = parcel.location?.region || '';
    this.showParcelModal = true;
  }

  closeParcelModal() {
    this.showParcelModal = false;
  }

  saveParcel() {
    if (!this.currentParcel.ownerName || !this.currentParcel.cropType || !this.currentParcel.area) {
      this.alertService.warning('Veuillez remplir les champs obligatoires (Producteur, Culture et Superficie)');
      return;
    }

    const payload: Partial<Parcel> = {
      ...this.currentParcel,
      location: { lat: 16.033, lng: -16.483, region: this.regionInput || 'Sénégal' }
    };

    if (this.isEditing && this.currentParcel.id) {
      this.parcelService.update(this.currentParcel.id, payload).subscribe({
        next: () => {
          this.alertService.success('Parcelle modifiée avec succès');
          this.loadParcels();
          this.closeParcelModal();
        },
        error: (err) => this.alertService.error('Erreur lors de la modification : ' + err.message)
      });
    } else {
      this.parcelService.create(payload).subscribe({
        next: () => {
          this.alertService.success('Parcelle créée avec succès');
          this.loadParcels();
          this.closeParcelModal();
        },
        error: (err) => this.alertService.error('Erreur lors de la création : ' + err.message)
      });
    }
  }

  openDetailsModal(parcel: Parcel) {
    this.selectedParcelDetails = parcel;
  }

  openDeleteModal(parcel: Parcel) {
    this.alertService.confirm({
      title: 'Supprimer la parcelle ?',
      message: `Cette action est définitive et supprimera toutes les données agronomiques associées pour ${parcel.ownerName}.`,
      confirmText: 'SUPPRIMER',
      confirmButtonColor: 'bg-red-600 hover:bg-red-700 shadow-red-600/20',
      onConfirm: () => {
        this.parcelService.delete(parcel.id).subscribe({
          next: () => {
            this.alertService.success('Parcelle supprimée avec succès');
            this.loadParcels();
          },
          error: (err) => this.alertService.error('Erreur lors de la suppression : ' + err.message)
        });
      }
    });
  }

  openAssignModal(parcel: Parcel) {
    this.assignParcel = parcel;
    this.assignTechnicianInput = parcel.technician === 'Non affecté' ? '' : (parcel.technician || '');
    this.showAssignModal = true;
  }

  closeAssignModal() {
    this.showAssignModal = false;
    this.assignParcel = null;
  }

  saveAssignment() {
    if (!this.assignParcel) return;
    this.loading = true;
    this.cdr.detectChanges();
    this.parcelService.update(this.assignParcel.id, { technician: this.assignTechnicianInput.trim() || 'Non affecté' }).subscribe({
      next: () => {
        this.alertService.success('Technicien affecté avec succès');
        this.closeAssignModal();
        this.loadParcels();
      },
      error: (err) => {
        this.alertService.error("Erreur lors de l'affectation : " + err.message);
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }
}
