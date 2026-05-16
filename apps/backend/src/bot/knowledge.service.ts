import { Injectable } from '@nestjs/common';

@Injectable()
export class KnowledgeService {
  /**
   * Retourne des fiches techniques locales basées sur des mots-clés
   */
  getLocalKnowledge(query: string): string {
    const queryLower = query.toLowerCase();
    let context = '';

    if (queryLower.includes('tomate') || queryLower.includes('mildiou')) {
      context +=
        ' [FICHE ISRA: La tomate au Sénégal nécessite une vigilance accrue sur le mildiou en saison des pluies. Traitement recommandé: Cuivre ou Mancozèbe.]';
    }

    if (queryLower.includes('riz') || queryLower.includes('vallée')) {
      context +=
        " [FICHE SAED: Dans la Vallée du Fleuve Sénégal, le riz IR64 est sensible à la pyriculariose. Vérifiez l'azote.]";
    }

    return context;
  }
}
