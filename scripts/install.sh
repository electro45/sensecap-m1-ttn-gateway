#!/bin/bash
# install.sh — Installation automatisée du packet forwarder SX1302 pour TTN
# Cible : Raspberry Pi 4 avec SenseCAP M1 (EU868)
# Usage : sudo bash install.sh

set -euo pipefail

# ─── Couleurs pour l'affichage ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }
info() { echo -e "${BLUE}[→]${NC} $*"; }

# ─── Répertoires ─────────────────────────────────────────────────────────────
INSTALL_DIR="/usr/local/bin"
CONF_DIR="/etc/sx1302_ttn"
BUILD_DIR="/opt/sx1302_hal"
SYSTEMD_DIR="/etc/systemd/system"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# ─── 0. Vérifications préalables ─────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SenseCAP M1 → TTN — Installation du packet forwarder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier qu'on tourne en root
if [[ $EUID -ne 0 ]]; then
    err "Ce script doit être exécuté en tant que root (sudo bash install.sh)"
    exit 1
fi

# Vérifier qu'on est sur un Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    err "Ce script est conçu pour un Raspberry Pi. Matériel non reconnu."
    err "Contenu de /proc/device-tree/model : $(cat /proc/device-tree/model 2>/dev/null || echo 'non disponible')"
    exit 1
fi

RPI_MODEL=$(cat /proc/device-tree/model)
log "Matériel détecté : $RPI_MODEL"

# Vérifier l'architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
    warn "Architecture : $ARCH — 64-bit (aarch64) recommandé pour sx1302_hal"
fi

echo ""
warn "⚠️  AVANT DE CONTINUER : vérifiez que l'antenne LoRa 868 MHz est branchée sur le SMA !"
echo -n "   Appuyez sur Entrée pour continuer (Ctrl+C pour annuler)..."
read -r

# ─── 1. Mise à jour du système ────────────────────────────────────────────────
echo ""
info "Étape 1/7 — Mise à jour des paquets système..."
apt-get update -q
apt-get install -y -q git build-essential libmpfr-dev
log "Dépendances installées"

# ─── 2. Activation des interfaces via raspi-config ───────────────────────────
echo ""
info "Étape 2/7 — Activation de I2C, SPI et UART..."

raspi-config nonint do_i2c 0
raspi-config nonint do_spi 0
raspi-config nonint do_serial_hw 0
raspi-config nonint do_serial_cons 1

log "I2C activé"
log "SPI activé"
log "UART matériel activé (login shell désactivé)"

# ─── 3. Clonage et compilation de sx1302_hal ─────────────────────────────────
echo ""
info "Étape 3/7 — Clonage et compilation de sx1302_hal..."

if [[ -d "$BUILD_DIR" ]]; then
    warn "$BUILD_DIR existe déjà — mise à jour..."
    cd "$BUILD_DIR"
    git pull --quiet
else
    git clone --quiet https://github.com/Lora-net/sx1302_hal.git "$BUILD_DIR"
    cd "$BUILD_DIR"
fi

make clean all 2>&1 | tail -5
log "sx1302_hal compilé dans $BUILD_DIR"

# ─── 4. Installation des binaires ────────────────────────────────────────────
echo ""
info "Étape 4/7 — Installation des binaires..."

cp -f "$BUILD_DIR/packet_forwarder/lora_pkt_fwd" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/lora_pkt_fwd"
log "lora_pkt_fwd → $INSTALL_DIR/lora_pkt_fwd"

cp -f "$SCRIPT_DIR/reset_lgw.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/reset_lgw.sh"
log "reset_lgw.sh → $INSTALL_DIR/reset_lgw.sh"

# ─── 5. Installation de la configuration ─────────────────────────────────────
echo ""
info "Étape 5/7 — Installation de la configuration TTN EU868..."

mkdir -p "$CONF_DIR"

CONFIG_SRC="$REPO_DIR/config/global_conf.json.sx1250.EU868.ttn"
if [[ -f "$CONFIG_SRC" ]]; then
    cp -f "$CONFIG_SRC" "$CONF_DIR/global_conf.json"
    log "Configuration TTN EU868 → $CONF_DIR/global_conf.json"
else
    err "Fichier de configuration non trouvé : $CONFIG_SRC"
    err "Clonez le dépôt complet avant de lancer ce script."
    exit 1
fi

# ─── 6. Installation du service systemd ──────────────────────────────────────
echo ""
info "Étape 6/7 — Installation du service systemd..."

SYSTEMD_SRC="$REPO_DIR/systemd/sx1302_forwarder.service"
if [[ -f "$SYSTEMD_SRC" ]]; then
    cp -f "$SYSTEMD_SRC" "$SYSTEMD_DIR/sx1302_forwarder.service"
    systemctl daemon-reload
    systemctl enable sx1302_forwarder.service
    log "Service systemd installé et activé au démarrage"
else
    err "Fichier service non trouvé : $SYSTEMD_SRC"
    exit 1
fi

# ─── 7. Premier démarrage — récupération et injection de l'EUI ───────────────
echo ""
info "Étape 7/7 — Démarrage du forwarder pour récupérer l'EUI concentrateur..."
echo ""

# Lancer le forwarder brièvement pour capturer l'EUI matériel
EUI_RAW=$(cd "$INSTALL_DIR" && timeout 15 ./lora_pkt_fwd -c "$CONF_DIR/global_conf.json" 2>&1 \
    | grep -i "concentrator EUI" | grep -oE '0x[0-9a-fA-F]+' | head -1)

if [[ -n "$EUI_RAW" ]]; then
    # Supprimer le préfixe 0x et mettre en majuscules
    EUI=$(echo "$EUI_RAW" | sed 's/0x//' | tr '[:lower:]' '[:upper:]')
    log "EUI concentrateur détecté : $EUI"
    # Injecter l'EUI réel dans la configuration (remplace le placeholder)
    sed -i "s/AA555A0000000000/$EUI/" "$CONF_DIR/global_conf.json"
    log "gateway_ID mis à jour dans $CONF_DIR/global_conf.json"
else
    warn "EUI non détecté — vérifiez le câblage et reset_lgw.sh"
    EUI="<EUI_NON_DETECTE>"
fi

echo ""

# ─── Résumé et instructions ───────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  Installation terminée !${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Prochaines étapes :"
echo ""
echo "  1. Enregistrez votre gateway sur TTN :"
echo "     https://console.cloud.thethings.network/"
echo "     → Gateways → Register gateway"
echo "     → Gateway EUI : $EUI"
echo "     → Frequency plan : Europe 863-870 MHz"
echo "     → Server : eu1.cloud.thethings.network"
echo ""
echo "  2. Démarrez le service :"
echo "     sudo systemctl start sx1302_forwarder"
echo ""
echo "  3. Suivez les logs :"
echo "     sudo journalctl -u sx1302_forwarder -f"
echo ""
echo "  Documentation complète :"
echo "  https://github.com/electro45/sensecap-m1-lorawan-gateway"
echo ""
