# 03 — Premier boot et configuration via raspi-config

## Objectif

Se connecter au Raspberry Pi en SSH et activer les interfaces matérielles nécessaires au concentrateur SX1302 : **I2C**, **SPI**, et le **port série** (UART matériel, login shell désactivé).

---

## Étape 1 : Remontage et mise sous tension

1. Rebranchez le câble coaxial U.FL sur le module SX1302.
2. **Branchez l'antenne 868 MHz** sur le connecteur SMA externe.
3. Rebranchez le câble Ethernet (recommandé pour le premier boot).
4. Replacez le couvercle et revissez les 4 vis.
5. Alimentez via le câble USB-C (alimentation ≥ 3A recommandée).

> ⚠️ **Ne jamais mettre sous tension sans antenne LoRa 868 MHz branchée sur le SMA.**

---

## Étape 2 : Trouver l'adresse IP du Pi

Le Pi obtient son IP via DHCP. Plusieurs méthodes :

### Via votre box/routeur

Consultez la liste DHCP de votre routeur et cherchez l'hôte `sensecap-gw`.

### Via nmap (Linux/macOS)

```bash
# Remplacez 192.168.1.0/24 par votre sous-réseau
nmap -sn 192.168.1.0/24 | grep -i "sensecap\|raspberry"
```

### Via avahi/mDNS (si votre réseau le supporte)

```bash
ping sensecap-gw.local
```

---

## Étape 3 : Connexion SSH

```bash
ssh pi@sensecap-gw.local
# ou avec l'IP directe :
ssh pi@192.168.1.XXX
```

À la première connexion, acceptez l'empreinte RSA du serveur (`yes`).

Vérifiez que le Pi est bien à jour :

```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

Reconnectez-vous après le reboot.

---

## Étape 4 : Configuration via raspi-config

Lancez l'outil de configuration :

```bash
sudo raspi-config
```

### 4a — Activer I2C

```
Interface Options → I2C → Yes
```

Le bus I2C est utilisé par le module SX1302 pour la configuration interne du concentrateur.

### 4b — Activer SPI

```
Interface Options → SPI → Yes
```

Le concentrateur SX1302 communique avec le Raspberry Pi via **SPI0** (broches GPIO 9, 10, 11 + CE0/CE1).

### 4c — Configurer le port série (UART)

```
Interface Options → Serial Port →
  Would you like a login shell to be accessible over the serial port? → No
  Would you like the serial port hardware to be enabled?              → Yes
```

> **Important** : le login shell sur le port série DOIT être désactivé. Le laisser actif crée des conflits avec l'UART utilisé par certains composants du module SX1302. Seul le **hardware UART** (`/dev/ttyAMA0` ou `/dev/ttyS0`) doit être activé.

### 4d — Mode non-interactif (alternative script)

Si vous préférez tout faire en ligne de commande (pour l'automatisation) :

```bash
# Activer I2C
sudo raspi-config nonint do_i2c 0

# Activer SPI
sudo raspi-config nonint do_spi 0

# Désactiver login shell série, activer hardware UART
sudo raspi-config nonint do_serial_hw 0
sudo raspi-config nonint do_serial_cons 1
```

---

## Étape 5 : Finaliser et redémarrer

Quittez raspi-config (`Finish`) et redémarrez :

```bash
sudo reboot
```

---

## Étape 6 : Vérification post-reboot

Après reconnexion SSH, vérifiez que les interfaces sont bien activées :

```bash
# I2C
ls /dev/i2c-*
# Attendu : /dev/i2c-1

# SPI
ls /dev/spi*
# Attendu : /dev/spidev0.0  /dev/spidev0.1

# UART
ls /dev/ttyAMA0
# Attendu : /dev/ttyAMA0
```

Vérifiez aussi les modules kernel chargés :

```bash
lsmod | grep -E "spi|i2c"
# Attendu : spi_bcm2835, i2c_bcm2835, i2c_dev
```

Si `/dev/spidev0.0` est absent, ajoutez manuellement dans `/boot/firmware/config.txt` :

```ini
dtparam=spi=on
dtparam=i2c_arm=on
enable_uart=1
```

---

## Étape suivante

Passez à [04 — Installation de sx1302_hal](04-installation-sx1302-hal.md).
