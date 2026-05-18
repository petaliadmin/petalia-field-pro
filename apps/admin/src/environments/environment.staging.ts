/**
 * Environnement de staging — l'EC2 actuel sert de bac à sable de
 * pré-production. Conservé en HTTPS dès que le certificat sera émis ;
 * temporairement HTTP pour conserver la compatibilité avec le déploiement
 * existant.
 */
export const environment = {
  production: false,
  apiUrl: 'http://52.73.53.182:3000',
};
