#!/usr/bin/env bash
# Script de déploiement vers l'EC2 Petalia
# Usage : ./deploy.sh [chemin/vers/cle.pem]
# Exemple : ./deploy.sh ~/.ssh/petalia-ec2.pem

set -euo pipefail

EC2_IP="52.73.53.182"
EC2_USER="${EC2_USER:-ubuntu}"
PEM_KEY="${1:-~/.ssh/petalia-ec2.pem}"
REMOTE_DIR="/home/${EC2_USER}/petalia"

echo "==> Déploiement vers ${EC2_USER}@${EC2_IP}"

# 1. Copier le code (hors node_modules et cache Angular)
echo "==> Synchronisation des fichiers..."
rsync -avz --progress \
  --exclude 'node_modules' \
  --exclude '.angular' \
  --exclude 'dist' \
  --exclude '.git' \
  -e "ssh -i ${PEM_KEY} -o StrictHostKeyChecking=no" \
  . "${EC2_USER}@${EC2_IP}:${REMOTE_DIR}"

# 2. Lancer docker-compose sur l'EC2
echo "==> Démarrage des conteneurs en production..."
ssh -i "${PEM_KEY}" -o StrictHostKeyChecking=no "${EC2_USER}@${EC2_IP}" bash <<EOF
  cd ${REMOTE_DIR}
  docker compose -f docker-compose.prod.yml pull 2>/dev/null || true
  docker compose -f docker-compose.prod.yml up -d --build
  echo "==> Statut des conteneurs :"
  docker compose -f docker-compose.prod.yml ps
EOF

echo ""
echo "✓  Déploiement terminé"
echo "   API : http://${EC2_IP}:3000"
echo "   Logs : ssh -i ${PEM_KEY} ${EC2_USER}@${EC2_IP} 'docker compose -f ${REMOTE_DIR}/docker-compose.prod.yml logs -f backend'"
