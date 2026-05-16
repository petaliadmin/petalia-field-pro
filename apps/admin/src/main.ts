import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app/app.routes';
import { provideHttpClient } from '@angular/common/http';
import {
  LUCIDE_ICONS,
  LucideIconProvider,
  LayoutDashboard,
  Microscope,
  Map,
  Settings,
  LogOut,
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
  Leaf
} from 'lucide-angular';

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(),
    {
      provide: LUCIDE_ICONS,
      multi: true,
      useValue: new LucideIconProvider({
        LayoutDashboard,
        Microscope,
        Map,
        Settings,
        LogOut,
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
        Leaf
      })
    }
  ]
}).catch(err => console.error(err));
