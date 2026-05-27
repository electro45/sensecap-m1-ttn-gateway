#!/bin/bash
# harden.sh — Durcissement sécurité post-installation
# Usage : sudo bash harden.sh
# À lancer une seule fois après install.sh + setup-chirpstack.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
info() { echo -e "${BLUE}[→]${NC} $*"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SenseCAP M1 — Durcissement sécurité"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[✗]${NC} Ce script doit être exécuté en root (sudo bash harden.sh)" >&2
    exit 1
fi

# ─── 1. Révoquer le sudo sans mot de passe ───────────────────────────────────
echo ""
info "Étape 1/4 — Révocation du sudo NOPASSWD..."

if [[ -f /etc/sudoers.d/gateway ]]; then
    rm -f /etc/sudoers.d/gateway
    log "Sudo NOPASSWD révoqué pour l'utilisateur gateway"
else
    warn "Fichier /etc/sudoers.d/gateway absent — sudo NOPASSWD déjà restreint"
fi

# ─── 2. Redis — activer l'authentification ───────────────────────────────────
echo ""
info "Étape 2/4 — Activation de l'authentification Redis..."

REDIS_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
REDIS_CONF="/etc/redis/redis.conf"

if [[ -f "$REDIS_CONF" ]]; then
    # Ajouter ou remplacer la directive requirepass
    if grep -q "^requirepass" "$REDIS_CONF"; then
        sed -i "s|^requirepass.*|requirepass ${REDIS_PASS}|" "$REDIS_CONF"
    else
        echo "requirepass ${REDIS_PASS}" >> "$REDIS_CONF"
    fi
    systemctl restart redis-server
    log "Redis : authentification activée"

    # Mettre à jour la config ChirpStack pour qu'il s'authentifie à Redis
    CS_TOML="/etc/chirpstack/chirpstack.toml"
    if [[ -f "$CS_TOML" ]]; then
        # Format attendu : redis://localhost:6379 → redis://:PASSWORD@localhost:6379
        sed -i "s|redis://localhost|redis://:${REDIS_PASS}@localhost|g" "$CS_TOML"
        sed -i "s|redis://127.0.0.1|redis://:${REDIS_PASS}@127.0.0.1|g" "$CS_TOML"
        log "chirpstack.toml : Redis URL mise à jour avec authentification"
        systemctl restart chirpstack
    fi
else
    warn "Config Redis introuvable à $REDIS_CONF — ignoré"
fi

# ─── 3. SSH — désactiver l'authentification par mot de passe ─────────────────
echo ""
info "Étape 3/4 — Durcissement SSH..."

SSHD_CONF="/etc/ssh/sshd_config"

# Vérifier qu'une clé SSH publique est présente avant de bloquer les mots de passe
GATEWAY_KEYS="/home/gateway/.ssh/authorized_keys"
if [[ ! -f "$GATEWAY_KEYS" ]] || [[ ! -s "$GATEWAY_KEYS" ]]; then
    warn "Aucune clé SSH trouvée dans $GATEWAY_KEYS"
    warn "Ajoutez votre clé publique avant de désactiver l'auth par mot de passe :"
    warn "  ssh-copy-id -i ~/.ssh/id_ed25519.pub gateway@<IP>"
    warn "Étape SSH ignorée — relancez le script après avoir ajouté votre clé."
else
    # Désactiver l'authentification par mot de passe
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONF"
    sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD_CONF"
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONF"
    systemctl reload sshd
    log "SSH : authentification par mot de passe désactivée, root login interdit"
fi

# ─── 4. fail2ban — protection contre les attaques SSH ────────────────────────
echo ""
info "Étape 4/4 — Installation de fail2ban..."

apt-get install -y -q fail2ban

tee /etc/fail2ban/jail.d/sshd.local > /dev/null <<'EOF'
[sshd]
enabled = true
maxretry = 5
bantime  = 3600
findtime = 600
EOF

systemctl enable --now fail2ban
log "fail2ban installé et actif (5 tentatives → bannissement 1h)"

# ─── Résumé ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  Durcissement terminé !${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}  Action manuelle requise :${NC}"
echo "  Changez le mot de passe admin ChirpStack dans l'interface web :"
echo "  http://$(hostname -I | awk '{print $1}'):8080 → Profil → Change password"
echo ""
