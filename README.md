# SenseCAP M1 → Gateway LoRaWAN EU868 (TTN + ChirpStack)

[![Licence MIT](https://img.shields.io/badge/Licence-MIT-green.svg)](LICENSE)
[![TTN](https://img.shields.io/badge/The%20Things%20Network-compatible-blue.svg)](https://www.thethingsnetwork.org/)
[![ChirpStack](https://img.shields.io/badge/ChirpStack-v4-purple.svg)](https://www.chirpstack.io/)
[![LoRaWAN EU868](https://img.shields.io/badge/LoRaWAN-EU868-orange.svg)](https://lora-alliance.org/)

Recyclez votre ancien hotspot **SenseCAP M1** (ex-réseau Helium) en **gateway LoRaWAN publique** connectée à [The Things Network](https://www.thethingsnetwork.org/) et/ou à un serveur **[ChirpStack v4](https://www.chirpstack.io/)** local. Ce guide documente la procédure complète pour la variante EU868 (Raspberry Pi 4 + concentrateur SX1302/SX1250).

---

> ⚠️ **AVERTISSEMENT IMPORTANT**
> Ne jamais alimenter la gateway sans antenne LoRa **868 MHz** branchée sur le connecteur SMA.
> Faire fonctionner le concentrateur SX1302 sans charge d'antenne peut griller définitivement le composant RF.

---

## Matériel concerné

| Composant | Détail |
|-----------|--------|
| Boîtier | SenseCAP M1 (Seeed Studio) |
| SoC | Raspberry Pi 4 Compute Module (CM4) ou RPi 4 Model B |
| Concentrateur LoRa | Semtech SX1302 + SX1250 (mini-PCIe) |
| Bande de fréquence | EU868 (863–870 MHz) |
| Interface | SPI |

## Prérequis matériels

- Tournevis Philips PH0 et PH1
- Pince à bec fin (extraction de la microSD)
- Lecteur microSD (USB ou intégré)
- Câble Ethernet ou accès WiFi
- **Antenne 868 MHz branchée en permanence** sur le SMA

## Prérequis logiciels

- [Raspberry Pi Imager](https://www.raspberrypi.com/software/) (Windows / macOS / Linux)
- Git, build-essential (installés sur le Pi)
- Compte sur [The Things Stack Community](https://console.cloud.thethings.network/) *(pour TTN)*

---

## Documentation étape par étape

### Phase 1 — Mise en service TTN (étapes 01 à 06)

| # | Fichier | Description |
|---|---------|-------------|
| 1 | [01 — Démontage](docs/01-materiel-demontage.md) | Ouverture du boîtier et extraction de la carte |
| 2 | [02 — Flash système](docs/02-flash-systeme.md) | Flasher Raspberry Pi OS Lite 64-bit |
| 3 | [03 — Premier boot](docs/03-premier-boot-raspi-config.md) | SSH, raspi-config, activation I2C/SPI |
| 4 | [04 — Installation sx1302_hal](docs/04-installation-sx1302-hal.md) | Compiler le packet forwarder Semtech |
| 5 | [05 — Configuration TTN](docs/05-configuration-ttn.md) | Enregistrement et configuration sur TTN |
| 6 | [06 — Tests et vérification](docs/06-tests-verification.md) | Valider la gateway et activer le service |

### Phase 2 — Ajout de ChirpStack en parallèle (étapes 07 à 08)

| # | Fichier | Description |
|---|---------|-------------|
| 7 | [07 — Packet Multiplexer](docs/07-packet-multiplexer.md) | Diffuser les trames vers TTN + ChirpStack simultanément |
| 8 | [08 — ChirpStack v4](docs/08-chirpstack.md) | Réseau LoRaWAN privé local, interface web :8080 |

---

## Installation rapide (script automatisé)

### Phase 1 — TTN

```bash
git clone https://github.com/electro45/sensecap-m1-lorawan-gateway.git
cd sensecap-m1-lorawan-gateway
sudo bash scripts/install.sh
```

### Phase 2 — Ajout ChirpStack (optionnel, après la phase 1)

```bash
sudo bash scripts/setup-chirpstack.sh
```

### Phase 3 — Durcissement sécurité (recommandé)

```bash
sudo bash scripts/harden.sh
```

Révoque le sudo NOPASSWD, active l'auth Redis, désactive l'auth SSH par mot de passe (si une clé SSH est déjà déposée), installe fail2ban.

> Les scripts doivent être exécutés sur le Raspberry Pi lui-même, **pas sur votre machine hôte**.

---

## Résultat attendu

### Avec TTN seul (phase 1)

- La **gateway apparaît en vert** dans la [console TTN](https://console.cloud.thethings.network/)
- Les trames LoRaWAN des objets à portée sont remontées vers TTN
- La gateway est marquée **publique** et contribue à la couverture communautaire

### Avec ChirpStack en plus (phase 2)

```
lora_pkt_fwd → packet-multiplexer:1700
                  ├── TTN eu1.cloud.thethings.network:1700
                  └── ChirpStack Gateway Bridge:1701
                             │
                        ChirpStack http://<ip>:8080
```

- TTN reste connectée (gateway toujours verte)
- ChirpStack accessible en local sur `:8080` (login `admin` / `admin` à changer)
- Vos propres capteurs LoRaWAN enregistrables et décodables localement

---

## Contenu du dépôt

```
sensecap-m1-lorawan-gateway/
├── README.md
├── docs/
│   ├── 01-materiel-demontage.md
│   ├── 02-flash-systeme.md
│   ├── 03-premier-boot-raspi-config.md
│   ├── 04-installation-sx1302-hal.md
│   ├── 05-configuration-ttn.md
│   ├── 06-tests-verification.md
│   ├── 07-packet-multiplexer.md       ← Phase 2
│   └── 08-chirpstack.md               ← Phase 2
├── config/
│   ├── global_conf.json.sx1250.EU868.ttn
│   └── packet-multiplexer.toml        ← Phase 2
├── scripts/
│   ├── install.sh                     ← Phase 1
│   ├── setup-chirpstack.sh            ← Phase 2
│   └── reset_lgw.sh
└── systemd/
    ├── sx1302_forwarder.service
    └── packet-multiplexer.service     ← Phase 2
```

---

## Licence

Ce projet est distribué sous licence [MIT](LICENSE).

Contributions bienvenues — ouvrez une *issue* ou une *pull request* !
