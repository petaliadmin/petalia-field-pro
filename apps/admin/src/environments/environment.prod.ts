/**
 * Environnement de production. Substitué par angular.json (fileReplacements)
 * lors du build `ng build --configuration production`.
 *
 * Le domaine et le schéma HTTPS sont obligatoires en production : le JWT
 * transite en clair sur HTTP et toute requête peut être interceptée.
 */
export const environment = {
  production: true,
  apiUrl: 'http://52.73.53.182:3000',
};
