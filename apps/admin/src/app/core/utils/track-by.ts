/**
 * Helper trackBy générique pour les *ngFor sur des collections
 * d'entités identifiées par un champ `id`. Évite à Angular de
 * recréer les nœuds DOM à chaque rechargement de la liste.
 */
export function trackById<T extends { id: string }>(_index: number, item: T): string {
  return item.id;
}
