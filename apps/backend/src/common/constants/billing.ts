/**
 * Tarifs centralisés appliqués aux services facturés sur le wallet
 * du technicien. Tous les montants sont en XOF (Franc CFA), unité entière.
 *
 * NB : pour les demandes d'avis expert, le tarif réel utilisé est
 * `Expert.consultationFee` quand un expert est explicitement choisi.
 * `EXPERT_REQUEST_DEFAULT_FEE_XOF` n'est utilisé que comme repli quand
 * aucun expert n'est ciblé (file globale).
 */
export const DIAGNOSTIC_FEE_XOF = 500;
export const EXPERT_REQUEST_DEFAULT_FEE_XOF = 1500;
