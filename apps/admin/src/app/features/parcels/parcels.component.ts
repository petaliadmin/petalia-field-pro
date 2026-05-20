import { Component, OnInit, AfterViewInit, OnDestroy, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideAngularModule } from 'lucide-angular';
import { takeUntil, forkJoin, interval, switchMap, take, takeWhile } from 'rxjs';
import { ParcelService, Parcel, ParcelStatus } from '../../core/services/parcel.service';
import { AlertConfirmService } from '../../core/services/alert-confirm.service';
import { environment } from '../../../environments/environment';
import { AdvancedImageAnalyzerComponent } from '../../components/advanced-image-analyzer/advanced-image-analyzer.component';
import { trackById } from '../../core/utils/track-by';
import { BaseComponent } from '../../core/base/base.component';
import { DEFAULT_LAT, DEFAULT_LNG } from '../../core/constants/app.constants';
import * as leafletNamespace from 'leaflet';
const L = (leafletNamespace as any).default || leafletNamespace;

@Component({
  selector: 'app-parcels',
  standalone: true,
  imports: [CommonModule, FormsModule, LucideAngularModule, AdvancedImageAnalyzerComponent],
  templateUrl: './parcels.component.html',
  styles: [`:host { display: block; }`]
})
export class ParcelsComponent extends BaseComponent implements OnInit, AfterViewInit, OnDestroy {
  readonly trackById = trackById;
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
  latestAnalysis: any = null;
  timeseries: any[] = [];
  geospatialLoading = false;

  /** Backend-proxied URL for the Sentinel-2 thumbnail (avoids GEE auth issues in the browser). */
  thumbnailProxyUrl: string | null = null;
  /** Backend-proxied tile URL template for Leaflet (replaces GEE tile URL directly). */
  satelliteTileUrl: string | null = null;
  /** Leaflet satellite tile layer — removed when switching parcels. */
  private satelliteLayer: L.TileLayer | null = null;

  showAssignModal = false;
  assignParcel: Parcel | null = null;
  assignTechnicianInput = '';

  activeView: 'split' | 'map' | 'list' = 'split';
  map: L.Map | null = null;
  parcelLayers: L.FeatureGroup | null = null;

  private parcelService = inject(ParcelService);
  private alertService = inject(AlertConfirmService);
  private cdr = inject(ChangeDetectorRef);

  ngOnInit() {
    (window as any).angularParcelsComponentRef = {
      openDetails: (id: string) => {
        const found = this.parcels.find(p => p.id === id);
        if (found) {
          this.openDetailsModal(found);
          this.cdr.markForCheck();
        }
      }
    };
    this.loadParcels();
  }

  loadParcels() {
    this.loading = true;
    this.parcelService.getAll().pipe(takeUntil(this.destroy$)).subscribe({
      next: (data) => {
        this.parcels = data;
        this.loading = false;
        this.cdr.markForCheck();
        setTimeout(() => {
          this.initMap();
        }, 150);
      },
      error: () => {
        this.loading = false;
        this.cdr.markForCheck();
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
    window.open(`${environment.apiUrl}/parcels/passport/${id}`, '_blank');
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
      location: { lat: DEFAULT_LAT, lng: DEFAULT_LNG, region: this.regionInput || 'Sénégal' }
    };

    if (this.isEditing && this.currentParcel.id) {
      this.parcelService.update(this.currentParcel.id, payload).pipe(takeUntil(this.destroy$)).subscribe({
        next: () => {
          this.alertService.success('Parcelle modifiée avec succès');
          this.loadParcels();
          this.closeParcelModal();
        },
        error: (err) => this.alertService.error('Erreur lors de la modification : ' + err.message)
      });
    } else {
      this.parcelService.create(payload).pipe(takeUntil(this.destroy$)).subscribe({
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
    this.latestAnalysis = null;
    this.timeseries = [];
    this.loadGeospatialData(parcel.id);
  }

  loadGeospatialData(parcelId: string) {
    this.geospatialLoading = true;
    this.cdr.markForCheck();

    forkJoin({
      latest: this.parcelService.getLatestAnalysis(parcelId),
      timeseries: this.parcelService.getTimeseries(parcelId)
    }).pipe(takeUntil(this.destroy$)).subscribe({
      next: (res) => {
        this.latestAnalysis = res.latest;
        this.timeseries = res.timeseries || [];
        // Always use the backend-proxied URLs — never a direct GEE URL
        this.thumbnailProxyUrl = this.parcelService.getThumbnailUrl(parcelId);
        this.satelliteTileUrl = this.parcelService.getTileUrlTemplate(parcelId);
        this.overlayGeeSatelliteLayer();
        this.geospatialLoading = false;
        this.cdr.markForCheck();
      },
      error: (err) => {
        console.error('Failed to load geospatial data', err);
        // Still set proxy URL as a fallback attempt
        this.thumbnailProxyUrl = this.parcelService.getThumbnailUrl(parcelId);
        this.geospatialLoading = false;
        this.cdr.markForCheck();
      }
    });
  }

  /**
   * Adds (or replaces) a Leaflet tile layer that proxies GEE satellite imagery
   * through the backend, so the browser never needs to authenticate with GEE.
   */
  private overlayGeeSatelliteLayer() {
    const map = this.map;
    const tileUrl = this.satelliteTileUrl;
    if (!map || !tileUrl) return;
    // Remove the previous satellite layer if it exists
    if (this.satelliteLayer) {
      map.removeLayer(this.satelliteLayer);
      this.satelliteLayer = null;
    }
    const layer = L.tileLayer(tileUrl, {
      maxZoom: 19,
      opacity: 0.85,
      attribution: '© Google Earth Engine / Sentinel-2'
    });
    layer.addTo(map);
    this.satelliteLayer = layer;
  }

  refreshGeospatialData() {
    if (!this.selectedParcelDetails) return;
    const targetParcelId = this.selectedParcelDetails.id;
    this.geospatialLoading = true;
    this.cdr.markForCheck();

    this.parcelService.triggerAnalysis(targetParcelId)
      .pipe(
        takeUntil(this.destroy$),
        switchMap(() => {
          // Poll every 2.5 seconds for up to 12 times (30 seconds total)
          return interval(2500).pipe(
            switchMap(() => forkJoin({
              latest: this.parcelService.getLatestAnalysis(targetParcelId),
              timeseries: this.parcelService.getTimeseries(targetParcelId)
            })),
            take(12),
            takeWhile(
              (res) => res.latest && res.latest.status !== 'COMPLETED' && res.latest.status !== 'FAILED',
              true // include the last element (so we get the COMPLETED or FAILED response)
            )
          );
        })
      )
      .subscribe({
        next: (res) => {
          if (this.selectedParcelDetails?.id !== targetParcelId) return;

          this.latestAnalysis = res.latest;
          this.timeseries = res.timeseries || [];
          
          if (res.latest?.status === 'COMPLETED') {
            this.geospatialLoading = false;
            this.alertService.success('Analyse GEE terminée avec succès !');
          } else if (res.latest?.status === 'FAILED') {
            this.geospatialLoading = false;
            this.alertService.error("L'analyse GEE a échoué.");
          }
          this.cdr.markForCheck();
        },
        error: (err) => {
          if (this.selectedParcelDetails?.id !== targetParcelId) return;
          this.alertService.error('Erreur lors de la synchronisation GEE : ' + err.message);
          this.geospatialLoading = false;
          this.cdr.markForCheck();
        }
      });
  }

  handleImageError(event: Event) {
    const img = event.target as HTMLImageElement;
    img.src = 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&q=80&w=600';
  }


  openDeleteModal(parcel: Parcel) {
    this.alertService.confirm({
      title: 'Supprimer la parcelle ?',
      message: `Cette action est définitive et supprimera toutes les données agronomiques associées pour ${parcel.ownerName}.`,
      confirmText: 'SUPPRIMER',
      confirmButtonColor: 'bg-red-600 hover:bg-red-700 shadow-red-600/20',
      onConfirm: () => {
        this.parcelService.delete(parcel.id).pipe(takeUntil(this.destroy$)).subscribe({
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
    this.parcelService.update(this.assignParcel.id, { technician: this.assignTechnicianInput.trim() || 'Non affecté' })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.alertService.success('Technicien affecté avec succès');
          this.closeAssignModal();
          this.loadParcels();
        },
        error: (err) => {
          this.alertService.error("Erreur lors de l'affectation : " + err.message);
          this.loading = false;
          this.cdr.markForCheck();
        }
      });
  }

  ngAfterViewInit() {
    setTimeout(() => {
      this.initMap();
    }, 150);
  }

  override ngOnDestroy() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
    (window as any).angularParcelsComponentRef = null;
    super.ngOnDestroy();
  }

  initMap() {
    const mapEl = document.getElementById('map-admin');
    if (!mapEl || this.map) return;

    this.map = L.map('map-admin', {
      center: [DEFAULT_LAT, DEFAULT_LNG],
      zoom: 7,
      zoomControl: false
    });

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap contributors'
    }).addTo(this.map);

    L.control.zoom({
      position: 'bottomright'
    }).addTo(this.map);

    this.parcelLayers = L.featureGroup().addTo(this.map);

    if (this.parcels.length > 0) {
      this.updateMapFeatures();
    }
  }

  setView(view: 'split' | 'map' | 'list') {
    this.activeView = view;
    if (view === 'list') {
      if (this.map) {
        this.map.remove();
        this.map = null;
      }
    } else {
      setTimeout(() => {
        if (!this.map) {
          this.initMap();
        } else {
          this.map.invalidateSize();
          this.updateMapFeatures();
        }
      }, 150);
    }
    this.cdr.markForCheck();
  }

  updateMapFeatures() {
    const layers = this.parcelLayers;
    if (!this.map || !layers) return;

    layers.clearLayers();

    const renderable = this.filteredParcels;
    if (renderable.length === 0) return;

    const bounds: L.LatLngBoundsExpression = [];

    renderable.forEach(parcel => {
      const color = this.getStatusColor(parcel.status);
      let layer: L.Layer | null = null;

      // 1. Polygon rendering
      if (parcel.boundary && parcel.boundary.coordinates && parcel.boundary.coordinates.length > 0) {
        layer = L.geoJSON(parcel.boundary as any, {
          style: {
            color: color,
            fillColor: color,
            fillOpacity: 0.35,
            weight: 3,
            dashArray: '4'
          }
        });
      }

      // 2. Pulse Marker rendering
      if (parcel.location?.lat && parcel.location?.lng) {
        const latLng: [number, number] = [parcel.location.lat, parcel.location.lng];
        
        const markerIcon = L.divIcon({
          className: `pulse-marker-${parcel.status}`,
          iconSize: [14, 14],
          iconAnchor: [7, 7]
        });

        const pointMarker = L.marker(latLng, { icon: markerIcon });
        
        if (layer) {
          layer = L.featureGroup([layer, pointMarker]);
        } else {
          layer = pointMarker;
        }
        
        bounds.push(latLng);
      }

      if (layer) {
        const popupContent = `
          <div class="p-2 min-w-[200px]">
            <div class="flex items-center justify-between gap-3 border-b border-slate-100 pb-2 mb-2">
              <span class="text-xs font-black text-slate-800">${parcel.ownerName}</span>
              <span class="text-[9px] font-black px-1.5 py-0.5 rounded ${this.getStatusBgTextClass(parcel.status)}">
                ${this.statusLabel(parcel.status)}
              </span>
            </div>
            <div class="space-y-1 text-[10px] text-slate-500 font-medium mb-3">
              <div>Culture : <span class="font-bold text-slate-700">${parcel.cropType || 'Non spécifié'}</span></div>
              <div>Superficie : <span class="font-bold text-slate-700">${parcel.area} ha</span></div>
              <div>Région : <span class="font-bold text-slate-700">${parcel.location?.region || 'Saint-Louis'}</span></div>
            </div>
            <button onclick="window.angularParcelsComponentRef.openDetails('${parcel.id}')"
                    class="w-full py-2 bg-primary hover:bg-primary-dark text-white rounded-xl text-[10px] font-black text-center transition-all shadow-md shadow-primary/10">
              VOIR LES DÉTAILS
            </button>
          </div>
        `;
        layer.bindPopup(popupContent);
        layers.addLayer(layer);
      }
    });

    if (bounds.length > 0 && this.activeView !== 'list') {
      try {
        this.map.fitBounds(bounds, { padding: [50, 50], maxZoom: 14 });
      } catch (e) {
        console.warn('Could not fit map bounds:', e);
      }
    }
  }

  focusParcelOnMap(parcel: Parcel) {
    if (!this.map || !parcel.location?.lat || !parcel.location?.lng) return;

    if (this.activeView === 'list') {
      this.setView('split');
    }

    setTimeout(() => {
      this.map!.setView([parcel.location!.lat, parcel.location!.lng], 15);
      
      // Open matching popup
      this.parcelLayers!.eachLayer((layer: any) => {
        const popup = layer.getPopup();
        if (popup && popup.getContent().includes(parcel.id)) {
          layer.openPopup();
        }
      });
    }, 150);
  }

  getStatusColor(status: ParcelStatus): string {
    const colors: Record<ParcelStatus, string> = {
      healthy: '#10b981',
      water_stress: '#f59e0b',
      infection: '#ef4444',
      unknown: '#94a3b8'
    };
    return colors[status] || '#94a3b8';
  }

  getStatusBgTextClass(status: ParcelStatus): string {
    const classes: Record<ParcelStatus, string> = {
      healthy: 'bg-emerald-100 text-emerald-700',
      water_stress: 'bg-amber-100 text-amber-700',
      infection: 'bg-red-100 text-red-700',
      unknown: 'bg-slate-100 text-slate-600'
    };
    return classes[status] || 'bg-slate-100 text-slate-600';
  }
}
