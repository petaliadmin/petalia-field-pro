import { Component, OnInit, OnDestroy, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideAngularModule } from 'lucide-angular';
import { AlertConfirmService, AlertMessage, ConfirmDialogConfig } from '../../../core/services/alert-confirm.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-alert-confirm',
  standalone: true,
  imports: [CommonModule, LucideAngularModule],
  template: `
    <!-- Toast Alerts Container (Top Right) -->
    <div class="fixed top-6 right-6 z-[100] flex flex-col gap-3 max-w-sm w-full pointer-events-none">
      <div *ngFor="let alert of alerts" 
           class="pointer-events-auto flex items-start gap-3 p-4 rounded-2xl shadow-2xl border backdrop-blur-md transition-all animate-fade-in"
           [ngClass]="{
             'bg-emerald-50/95 border-emerald-200 text-emerald-900 shadow-emerald-500/10': alert.type === 'success',
             'bg-red-50/95 border-red-200 text-red-900 shadow-red-500/10': alert.type === 'error',
             'bg-amber-50/95 border-amber-200 text-amber-900 shadow-amber-500/10': alert.type === 'warning'
           }">
        <div class="p-2 rounded-xl shrink-0 mt-0.5"
             [ngClass]="{
               'bg-emerald-100 text-emerald-600': alert.type === 'success',
               'bg-red-100 text-red-600': alert.type === 'error',
               'bg-amber-100 text-amber-600': alert.type === 'warning'
             }">
          <lucide-icon [name]="alert.type === 'success' ? 'circle-check' : alert.type === 'error' ? 'circle-x' : 'circle-alert'" class="w-5 h-5"></lucide-icon>
        </div>
        <div class="flex-1 min-w-0">
          <h4 class="text-sm font-black leading-tight mb-0.5"
              [ngClass]="{
                'text-emerald-800': alert.type === 'success',
                'text-red-800': alert.type === 'error',
                'text-amber-800': alert.type === 'warning'
              }">{{ alert.title }}</h4>
          <p class="text-xs font-semibold opacity-90 leading-relaxed">{{ alert.message }}</p>
        </div>
        <button (click)="removeAlert(alert.id)" class="p-1 rounded-lg hover:bg-black/5 text-slate-400 hover:text-slate-600 transition-colors">
          <lucide-icon name="x" class="w-4 h-4"></lucide-icon>
        </button>
      </div>
    </div>

    <!-- Custom Confirm Dialog Modal -->
    <div *ngIf="confirmConfig" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[110] flex items-center justify-center p-4 animate-fade-in">
      <div class="bg-white rounded-[32px] p-8 max-w-md w-full shadow-2xl border border-gray-100 text-center relative overflow-hidden animate-scale-up">
        <div class="w-16 h-16 bg-amber-100 rounded-2xl flex items-center justify-center text-amber-600 mx-auto mb-6 shadow-inner">
          <lucide-icon name="circle-help" class="w-8 h-8"></lucide-icon>
        </div>
        <h3 class="text-xl font-black text-slate-900 mb-2">{{ confirmConfig.title }}</h3>
        <p class="text-sm text-slate-500 mb-8 font-medium leading-relaxed">{{ confirmConfig.message }}</p>

        <div class="flex gap-4">
          <button (click)="cancel()" class="flex-1 py-4 bg-gray-100 text-slate-700 rounded-2xl font-black text-sm hover:bg-gray-200 transition-all shadow-sm">
            {{ confirmConfig.cancelText || 'ANNULER' }}
          </button>
          <button (click)="confirm()" 
                  class="flex-1 py-4 text-white rounded-2xl font-black text-sm shadow-xl transition-all"
                  [ngClass]="confirmConfig.confirmButtonColor || 'bg-primary hover:bg-primary-dark shadow-primary/20'">
            {{ confirmConfig.confirmText || 'CONFIRMER' }}
          </button>
        </div>
      </div>
    </div>
  `
})
export class AlertConfirmComponent implements OnInit, OnDestroy {
  alerts: AlertMessage[] = [];
  confirmConfig: ConfirmDialogConfig | null = null;

  private alertService = inject(AlertConfirmService);
  private cdr = inject(ChangeDetectorRef);
  private sub1!: Subscription;
  private sub2!: Subscription;
  private timers = new Map<string, ReturnType<typeof setTimeout>>();

  ngOnInit() {
    this.sub1 = this.alertService.alerts$.subscribe(alert => {
      this.alerts.push(alert);
      this.cdr.detectChanges();
      if (alert.duration && alert.duration > 0) {
        const timer = setTimeout(() => {
          this.timers.delete(alert.id);
          this.removeAlert(alert.id);
        }, alert.duration);
        this.timers.set(alert.id, timer);
      }
    });

    this.sub2 = this.alertService.confirm$.subscribe(config => {
      this.confirmConfig = config;
      this.cdr.detectChanges();
    });
  }

  ngOnDestroy() {
    this.sub1?.unsubscribe();
    this.sub2?.unsubscribe();
    this.timers.forEach(timer => clearTimeout(timer));
    this.timers.clear();
  }

  removeAlert(id: string) {
    const timer = this.timers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(id);
    }
    this.alerts = this.alerts.filter(a => a.id !== id);
    this.cdr.detectChanges();
  }

  confirm() {
    if (this.confirmConfig) {
      this.confirmConfig.onConfirm();
      this.alertService.closeConfirm();
    }
  }

  cancel() {
    if (this.confirmConfig) {
      if (this.confirmConfig.onCancel) {
        this.confirmConfig.onCancel();
      }
      this.alertService.closeConfirm();
    }
  }
}
