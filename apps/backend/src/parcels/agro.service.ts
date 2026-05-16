import { Injectable } from '@nestjs/common';

@Injectable()
export class AgroService {
  /**
   * Calcule le score de santé global (0.0 à 1.0)
   * Formule simplifiée : Base (1.0) - Malus Temps - Malus Symptômes
   */
  calculateHealthScore(lastVisit: Date, symptoms: string[] = []): number {
    let score = 1.0;

    // Malus Temps : -0.05 par jour sans visite après 7 jours
    const daysSinceVisit = Math.floor(
      (new Date().getTime() - lastVisit.getTime()) / (1000 * 3600 * 24),
    );
    if (daysSinceVisit > 7) {
      score -= (daysSinceVisit - 7) * 0.05;
    }

    // Malus Symptômes (Exemples agronomiques réels au Sénégal)
    symptoms.forEach((s) => {
      const sLower = s.toLowerCase();
      if (sLower.includes('mildiou') || sLower.includes('chenille'))
        score -= 0.3;
      if (sLower.includes('carence')) score -= 0.15;
      if (sLower.includes('stress hydrique')) score -= 0.2;
    });

    return Math.max(0.1, Math.min(1.0, score));
  }

  getRiskLevel(score: number): 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' {
    if (score > 0.8) return 'LOW';
    if (score > 0.5) return 'MEDIUM';
    if (score > 0.3) return 'HIGH';
    return 'CRITICAL';
  }
}
