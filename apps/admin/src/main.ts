import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app/app.routes';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import {
  LUCIDE_ICONS,
  LucideIconProvider,
  LayoutDashboard,
  Microscope,
  Map,
  Settings,
  LogOut,
  LogIn,
  Bell,
  User,
  Users,
  TrendingUp,
  MapPin,
  CircleCheck,
  Clock,
  Search,
  Filter,
  CircleX,
  CircleAlert,
  ExternalLink,
  Calendar,
  UserPlus,
  EllipsisVertical,
  Shield,
  Smartphone,
  Mail,
  CircleCheckBig,
  Layers,
  Maximize2,
  Leaf,
  Wallet,
  Coins,
  X,
  Plus,
  Check,
  Eye,
  FileText,
  ArrowUpCircle,
  Scale,
  Sliders,
  Trash2,
  Send,
  MessageSquareText,
  CircleHelp,
  RotateCcw,
  Image,
  CheckCircle2,
  Sun,
  AlertTriangle,
  Flame,
  ZoomIn,
  Info,
  BarChart2,
  AlertCircle,
  Cpu,
  Globe,
  RotateCw,
  TrendingDown,
  Minus,
  ImageOff,
} from 'lucide-angular';

import { authInterceptor } from './app/core/interceptors/auth.interceptor';
import { errorInterceptor } from './app/core/interceptors/error.interceptor';

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([authInterceptor, errorInterceptor])),
    {
      provide: LUCIDE_ICONS,
      multi: true,
      useValue: new LucideIconProvider({
        LayoutDashboard,
        Microscope,
        Map,
        Settings,
        LogOut,
        LogIn,
        Bell,
        User,
        Users,
        TrendingUp,
        MapPin,
        CircleCheck,
        Clock,
        Search,
        Filter,
        CircleX,
        CircleAlert,
        ExternalLink,
        Calendar,
        UserPlus,
        EllipsisVertical,
        Shield,
        Smartphone,
        Mail,
        CircleCheckBig,
        Layers,
        Maximize2,
        Leaf,
        Wallet,
        Coins,
        X,
        Plus,
        Check,
        Eye,
        FileText,
        ArrowUpCircle,
        Scale,
        Sliders,
        Trash2,
        Send,
        MessageSquareText,
        CircleHelp,
        RotateCcw,
        Image,
        CheckCircle2,
        Sun,
        AlertTriangle,
        Flame,
        ZoomIn,
        Info,
        BarChart2,
        AlertCircle,
        Cpu,
        Globe,
        RotateCw,
        TrendingDown,
        Minus,
        ImageOff,
      }),
    },
  ],
}).catch((err) => {
  // Évite console.error en prod : on émet une alerte visuelle minimaliste.
  // L'errorInterceptor + ErrorHandler gèrent le runtime ; ce catch couvre le bootstrap.
  const root = document.body;
  if (root) {
    const banner = document.createElement('div');
    banner.style.cssText =
      'position:fixed;top:0;left:0;right:0;padding:16px;background:#dc2626;color:#fff;font-family:sans-serif;z-index:9999';
    banner.textContent = "Erreur d'initialisation Petalia Admin. Rechargez la page.";
    root.prepend(banner);
  }
  // En dev seulement
  if (!(window as any).__PROD__) {
    // eslint-disable-next-line no-console
    console.error('[Bootstrap]', err);
  }
});
