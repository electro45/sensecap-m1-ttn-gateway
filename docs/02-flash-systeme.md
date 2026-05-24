# 02 — Flash du système — Raspberry Pi OS Lite 64-bit

## Objectif

Flasher une nouvelle carte microSD avec **Raspberry Pi OS Lite 64-bit** (Bookworm ou ultérieur) pour remplacer l'image Helium propriétaire.

---

## Matériel nécessaire

- Carte microSD ≥ 8 Go (classe 10 / A1 recommandée)
- Lecteur microSD USB ou intégré au PC
- Ordinateur avec [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

---

## Étape 1 : Télécharger Raspberry Pi Imager

| Système | Lien |
|---------|------|
| Windows | Installeur `.exe` sur raspberrypi.com/software |
| macOS | Installeur `.dmg` |
| Linux (Debian/Ubuntu) | `sudo apt install rpi-imager` |

---

## Étape 2 : Flasher la carte

1. Insérez la carte microSD dans votre lecteur.
2. Lancez **Raspberry Pi Imager**.
3. Cliquez **Choisir l'OS** → **Raspberry Pi OS (other)** → **Raspberry Pi OS Lite (64-bit)**.

> Utilisez impérativement la version **64-bit** — la compilation de `sx1302_hal` nécessite un userland 64-bit pour les Raspberry Pi 4.

4. Cliquez **Choisir le stockage** → sélectionnez votre carte microSD.
5. Cliquez l'icône **⚙️ (engrenage)** ou **Ctrl+Shift+X** pour ouvrir les **options avancées**.

### Options avancées recommandées

```
☑ Définir le nom d'hôte :   sensecap-gw
☑ Activer SSH               (utiliser mot de passe)
    Nom d'utilisateur :      pi
    Mot de passe :           [choisissez un mot de passe fort]

☑ Configurer le WiFi (optionnel)
    SSID :                   [votre réseau]
    Mot de passe :           [votre clé WiFi]
    Pays WiFi :              FR

☑ Paramètres de langue
    Fuseau horaire :         Europe/Paris
    Type de clavier :        fr
```

> **WiFi** : si vous utilisez Ethernet, le WiFi peut être laissé non configuré. La configuration WiFi dans Imager évite de devoir connecter un écran et un clavier lors du premier boot.

6. Cliquez **Enregistrer** puis **Écrire**.
7. Confirmez l'avertissement d'effacement et attendez la fin du flash (2–5 minutes).
8. Imager vérifie automatiquement l'écriture — attendez la confirmation.

---

## Étape 3 : Vérification manuelle (optionnel)

Après le flash, la partition `bootfs` (FAT32) est visible depuis votre ordinateur.

Vérifiez la présence des fichiers suivants :

```
bootfs/
├── cmdline.txt
├── config.txt
├── ssh               ← fichier vide créant par Imager si SSH activé
└── firstrun.sh       ← script de première configuration (hostname, user, wifi)
```

Si le fichier `ssh` est absent et que vous n'avez pas activé SSH dans Imager :

```bash
# Depuis Linux/macOS, montez la partition bootfs et créez le fichier vide
touch /media/$USER/bootfs/ssh
```

---

## Étape 4 : Insertion de la carte dans le SenseCAP M1

1. Insérez la nouvelle carte microSD dans le slot push-push du Raspberry Pi (sens : contacts vers le bas, encoche vers l'arrière).
2. Appuyez jusqu'au clic.
3. **Ne rebranchez pas encore l'antenne U.FL** — vous le ferez après le remontage.

---

## Étape suivante

Passez à [03 — Premier boot et raspi-config](03-premier-boot-raspi-config.md).
