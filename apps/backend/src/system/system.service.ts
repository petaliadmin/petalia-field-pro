import { Injectable } from '@nestjs/common';
import { DEFAULT_AGRO_RULES, DEFAULT_SYMPTOMS, DEFAULT_CROPS } from './catalogs.data';

@Injectable()
export class SystemService {
  getCatalogs(clientVersion?: string) {
    const currentVersion = 'v3.1.0';

    if (clientVersion === currentVersion) {
      return {
        upToDate: true,
        catalogVersion: currentVersion,
        timestamp: new Date().toISOString(),
      };
    }

    return {
      upToDate: false,
      catalogVersion: currentVersion,
      timestamp: new Date().toISOString(),
      rules: DEFAULT_AGRO_RULES,
      symptoms: DEFAULT_SYMPTOMS,
      crops: DEFAULT_CROPS,
    };
  }
}
