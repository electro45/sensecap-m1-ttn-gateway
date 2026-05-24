# SenseCAP M1 → The Things Network (EU868)

[![Licence MIT](https://img.shields.io/badge/Licence-MIT-green.svg)](LICENSE)
[![TTN](https://img.shields.io/badge/The%20Things%20Network-compatible-blue.svg)](https://www.thethingsnetwork.org/)
[![LoRaWAN EU868](https://img.shields.io/badge/LoRaWAN-EU868-orange.svg)](https://lora-alliance.org/)

Recyclez votre ancien hotspot **SenseCAP M1** (ex-réseau Helium) en **gateway LoRaWAN publique** connectée à [The Things Network](https://www.thethingsnetwork.org/). Ce guide documente la procédure complète pour la variante EU868 (Raspberry Pi 4 + concentrateur SX1302/SX1250).

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
- Compte sur [The Things Stack Community](https://console.cloud.thethings.network/)

---

## Documentation étape par étape

| # | Fichier | Description |
|---|---------|-------------|
| 1 | [01 — Démontage](docs/01-materiel-demontage.md) | Ouverture du boîtier et extraction de la carte |
| 2 | [02 — Flash système](docs/02-flash-systeme.md) | Flasher Raspberry Pi OS Lite 64-bit |
| 3 | [03 — Premier boot](docs/03-premier-boot-raspi-config.md) | SSH, raspi-config, activation I2C/SPI |
| 4 | [04 — Installation sx1302_hal](docs/04-installation-sx1302-hal.md) | Compiler le packet forwarder Semtech |
| 5 | [05 — Configuration TTN](docs/05-configuration-ttn.md) | Enregistrement et configuration sur TTN |
| 6 | [06 — Tests et vérification](docs/06-tests-verification.md) | Valider la gateway et activer le service |

---

## Installation rapide (script automatisé)

Un script `install.sh` est disponible pour automatiser les étapes 3 à 6 :

```bash
git clone https://github.com/votre-utilisateur/sensecap-m1-ttn-gateway.git
cd sensecap-m1-ttn-gateway
chmod +x scripts/install.sh
sudo bash scripts/install.sh
```

> Le script doit être exécuté sur le Raspberry Pi lui-même, **pas sur votre machine hôte**.

---

## Résultat attendu

Une fois la procédure terminée :

- La **gateway apparaît en vert** (statut connecté) dans la [console TTN](https://console.cloud.thethings.network/)
- Les trames LoRaWAN des objets à portée sont remontées vers TTN
- La gateway est marquée **publique** et contribue à la couverture communautaire TTN
- Le service `sx1302_forwarder` démarre automatiquement au démarrage du Pi

```
INFO: [TTN] concentrator started, packet can now be received
INFO: [TTN] PUSH_ACK received from server eu1.cloud.thethings.network
```

---

## Contenu du dépôt

```
sensecap-m1-ttn-gateway/
├── README.md
├── docs/
│   ├── 01-materiel-demontage.md
│   ├── 02-flash-systeme.md
│   ├── 03-premier-boot-raspi-config.md
│   ├── 04-installation-sx1302-hal.md
│   ├── 05-configuration-ttn.md
│   └── 06-tests-verification.md
├── config/
│   └── global_conf.json.sx1250.EU868.ttn
├── scripts/
│   ├── install.sh
│   └── reset_lgw.sh
└── systemd/
    └── sx1302_forwarder.service
```

---

## Licence

Ce projet est distribué sous licence [MIT](LICENSE).

Contributions bienvenues — ouvrez une *issue* ou une *pull request* !
