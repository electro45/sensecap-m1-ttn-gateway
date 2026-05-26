#!/bin/bash
# setup-chirpstack.sh — Ajout de ChirpStack v4 + packet-multiplexer
# Prérequis : install.sh déjà exécuté, gateway TTN fonctionnelle
# Usage : sudo bash setup-chirpstack.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }
info() { echo -e "${BLUE}[→]${NC} $*"; }

CONF_DIR="/etc/sx1302_ttn"
PKTMUX_CONF_DIR="/etc/chirpstack-packet-multiplexer"
SYSTEMD_DIR="/etc/systemd/system"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SenseCAP M1 — Ajout ChirpStack v4 + Multiplexeur"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $EUID -ne 0 ]]; then
    err "Ce script doit être exécuté en tant que root (sudo bash setup-chirpstack.sh)"
    exit 1
fi

if [[ ! -f "$CONF_DIR/global_conf.json" ]]; then
    err "global_conf.json introuvable dans $CONF_DIR"
    err "Exécutez d'abord : sudo bash install.sh"
    exit 1
fi

# ─── 1. Dépôt APT ChirpStack ─────────────────────────────────────────────────
echo ""
info "Étape 1/5 — Ajout du dépôt APT ChirpStack v4..."

apt-get install -y -q apt-transport-https ca-certificates curl
install -d /etc/apt/keyrings

# Clé ChirpStack (compatible Debian Trixie / Sequoia)
curl -fsSL \
    "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1CE2AFD36DBCCA00&options=mr" \
    -o /etc/apt/keyrings/chirpstack.asc
chmod 0644 /etc/apt/keyrings/chirpstack.asc

echo "deb [signed-by=/etc/apt/keyrings/chirpstack.asc] \
https://artifacts.chirpstack.io/packages/4.x/deb stable main" \
    | tee /etc/apt/sources.list.d/chirpstack.list > /dev/null

apt-get update -q
log "Dépôt ChirpStack v4 ajouté"

# ─── 2. Installation de la stack complète ────────────────────────────────────
echo ""
info "Étape 2/5 — Installation Mosquitto, Postgres, Redis, ChirpStack..."

apt-get install -y -q \
    mosquitto mosquitto-clients \
    postgresql redis-server \
    chirpstack-packet-multiplexer \
    chirpstack-gateway-bridge \
    chirpstack

log "Paquets installés"

# ─── 3. Configuration du packet-multiplexer ──────────────────────────────────
echo ""
info "Étape 3/5 — Configuration du packet-multiplexer..."

# Copier notre config dans le répertoire attendu par le paquet
mkdir -p "$PKTMUX_CONF_DIR"
cp -f "$REPO_DIR/config/packet-multiplexer.toml" \
    "$PKTMUX_CONF_DIR/chirpstack-packet-multiplexer.toml"
log "Configuration multiplexeur → $PKTMUX_CONF_DIR/chirpstack-packet-multiplexer.toml"

# Rediriger lora_pkt_fwd vers le multiplexeur local
sed -i 's/"server_address": "eu1.cloud.thethings.network"/"server_address": "127.0.0.1"/' \
    "$CONF_DIR/global_conf.json"
log "global_conf.json : server_address → 127.0.0.1 (multiplexeur)"

# chirpstack-gateway-bridge : écouter sur :1701 (le mux prend le :1700)
BRIDGE_CONF="/etc/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml"
if [[ -f "$BRIDGE_CONF" ]]; then
    sed -i 's/udp_bind = "0.0.0.0:1700"/udp_bind = "0.0.0.0:1701"/' "$BRIDGE_CONF"
    log "chirpstack-gateway-bridge : UDP bind → :1701"
else
    warn "Config Gateway Bridge non trouvée à $BRIDGE_CONF — vérifiez manuellement"
fi

# ─── 4. Configuration Mosquitto ───────────────────────────────────────────────
echo ""
info "Étape 4/5 — Configuration Mosquitto..."

# Mosquitto 2.x refuse les connexions anonymes par défaut
tee /etc/mosquitto/conf.d/local.conf > /dev/null <<'EOF'
allow_anonymous true
listener 1883 127.0.0.1
EOF
systemctl restart mosquitto
log "Mosquitto configuré (accès anonyme local)"

# ─── 5. Base de données PostgreSQL + démarrage ───────────────────────────────
echo ""
info "Étape 5/5 — Initialisation PostgreSQL et démarrage des services..."

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='chirpstack'" \
    | grep -q 1 || \
    sudo -u postgres psql -c "CREATE ROLE chirpstack WITH LOGIN PASSWORD 'chirpstack';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='chirpstack'" \
    | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE chirpstack OWNER chirpstack;"

sudo -u postgres psql chirpstack -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" 2>/dev/null || true
log "Base PostgreSQL prête"

systemctl daemon-reload
systemctl enable --now \
    chirpstack-packet-multiplexer \
    chirpstack-gateway-bridge \
    chirpstack

# Redémarrer le forwarder pour qu'il pointe vers le multiplexeur
systemctl restart sx1302_forwarder
log "Tous les services démarrés"

# ─── Résumé ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  ChirpStack installé !${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Interface ChirpStack :"
IP=$(hostname -I | awk '{print $1}')
echo "  http://${IP}:8080"
echo "  Login par défaut : admin / admin"
echo ""
echo "  Flux des données :"
echo "  lora_pkt_fwd → multiplexeur:1700"
echo "    ├── TTN eu1.cloud.thethings.network:1700"
echo "    └── chirpstack-gateway-bridge:1701 → ChirpStack:8080"
echo ""
echo "  Logs utiles :"
echo "  sudo journalctl -u chirpstack-packet-multiplexer -f"
echo "  sudo journalctl -u chirpstack-gateway-bridge -f"
echo "  sudo journalctl -u chirpstack -f"
echo ""
