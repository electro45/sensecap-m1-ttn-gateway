# 04 — Installation et compilation de sx1302_hal

## Objectif

Compiler le **packet forwarder Semtech** (`sx1302_hal`) depuis les sources, en configurant les GPIOs correctes pour le SenseCAP M1.

---

## Brochage GPIO SenseCAP M1

Le SenseCAP M1 utilise un câblage spécifique entre le Raspberry Pi et le module SX1302. Ces numéros **doivent** correspondre exactement dans la configuration.

| Signal | GPIO BCM | Description |
|--------|----------|-------------|
| RESET concentrateur | **17** | Reset du SX1302 |
| POWER_EN | **18** | Alimentation du module RF |
| SX1261 RESET | **5** | Reset du LBT/spectral scan |
| AD5338R RESET | **13** | Reset du DAC audio (si présent) |
| SPI | 9, 10, 11, CE0 | Interface SPI0 standard |

> ⚠️ Ces GPIOs sont spécifiques au SenseCAP M1. D'autres gateways basées sur SX1302 (RAK7244, MNTD, etc.) utilisent des broches différentes.

---

## Étape 1 : Installation des dépendances

```bash
sudo apt update
sudo apt install -y git build-essential libmpfr-dev
```

---

## Étape 2 : Clonage du dépôt sx1302_hal

```bash
cd /opt
sudo git clone https://github.com/Lora-net/sx1302_hal.git
sudo chown -R pi:pi sx1302_hal
cd sx1302_hal
```

Vérifiez la branche utilisée (la branche `master` est stable pour production) :

```bash
git log --oneline -5
```

---

## Étape 3 : Compilation

```bash
make clean all
```

La compilation prend environ 2–3 minutes sur un Raspberry Pi 4.

Résultat attendu :

```
make[1]: Leaving directory '/opt/sx1302_hal/libloragw'
make[1]: Entering directory '/opt/sx1302_hal/packet_forwarder'
  CC      src/lora_pkt_fwd.c
  CC      src/jitqueue.c
  CC      src/parson.c
  LD      lora_pkt_fwd
make[1]: Leaving directory '/opt/sx1302_hal/packet_forwarder'
```

Vérifiez les binaires produits :

```bash
ls -la packet_forwarder/lora_pkt_fwd
ls -la tools/reset_lgw.sh
```

---

## Étape 4 : Configurer le script de reset GPIO

Le script `reset_lgw.sh` pilote les GPIOs de reset du concentrateur. Il faut l'adapter au SenseCAP M1.

Copiez le script du dépôt courant :

```bash
cp /chemin/vers/sensecap-m1-ttn-gateway/scripts/reset_lgw.sh tools/reset_lgw.sh
chmod +x tools/reset_lgw.sh
```

Ou éditez manuellement `tools/reset_lgw.sh` pour que les variables correspondent :

```bash
SX1302_RESET_PIN=17
SX1302_POWER_EN_PIN=18
SX1261_RESET_PIN=5
AD5338R_RESET_PIN=13
```

---

## Étape 5 : Copier la configuration TTN EU868

Copiez le fichier de configuration depuis ce dépôt vers le répertoire du forwarder :

```bash
cp /chemin/vers/sensecap-m1-ttn-gateway/config/global_conf.json.sx1250.EU868.ttn \
   packet_forwarder/global_conf.json
```

> Le fichier `global_conf.json` contient la configuration radio EU868 et les paramètres de connexion au serveur TTN (eu1.cloud.thethings.network:1700).

---

## Étape 6 : Premier test — récupération de l'EUI

L'EUI concentrateur (identifiant unique de la gateway) se lit dans la sortie du forwarder au démarrage.

```bash
cd packet_forwarder
sudo ./lora_pkt_fwd
```

Cherchez dans la sortie une ligne comme :

```
INFO: concentrator EUI: 0x58A0CBFFFE______
```

> **Notez cet EUI** — vous en aurez besoin pour enregistrer la gateway sur TTN (étape 05).

Arrêtez le forwarder avec **Ctrl+C** une fois l'EUI récupéré.

---

## Étape 7 : Installation dans le système

```bash
sudo cp packet_forwarder/lora_pkt_fwd /usr/local/bin/
sudo cp tools/reset_lgw.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/lora_pkt_fwd
sudo chmod +x /usr/local/bin/reset_lgw.sh

# Répertoire de configuration
sudo mkdir -p /etc/sx1302_ttn
sudo cp packet_forwarder/global_conf.json /etc/sx1302_ttn/global_conf.json
```

---

## Dépannage

### Erreur : `failed to open /dev/spidev0.0`

SPI non activé. Relancez `sudo raspi-config` → Interface Options → SPI → Yes.

### Erreur : `lgw_connect() failed`

GPIO de reset incorrects ou power enable non activé. Vérifiez les valeurs dans `reset_lgw.sh`.

### Erreur : `Permission denied` sur /dev/spidev0.0

Ajoutez l'utilisateur au groupe `spi` :

```bash
sudo usermod -aG spi pi
# Reconnectez-vous pour appliquer
```

### Concentrateur non détecté après reset

Vérifiez avec un oscilloscope ou un multimètre que GPIO17 passe bien à LOW pendant le reset, et que GPIO18 (POWER_EN) est bien à HIGH.

---

## Étape suivante

Passez à [05 — Configuration TTN](05-configuration-ttn.md).
