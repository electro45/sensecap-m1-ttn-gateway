# 01 — Matériel et démontage du SenseCAP M1

## Vue d'ensemble

Le SenseCAP M1 est un hotspot Helium produit par Seeed Studio. Il embarque un Raspberry Pi 4 (ou Compute Module 4) et un concentrateur LoRa SX1302 sur un module mini-PCIe. Cette page décrit comment l'ouvrir sans l'endommager pour remplacer la carte microSD système.

---

## Outils nécessaires

| Outil | Usage |
|-------|-------|
| Tournevis Philips PH0 | Vis du couvercle supérieur |
| Tournevis Philips PH1 | Vis de fond |
| Pince à bec fin (ou pince brucelles) | Extraction de la carte microSD |
| Spudger ou plectre en plastique | Clips latéraux |
| Antenne 868 MHz | À rebrancher avant toute mise sous tension |

> ⚠️ **Les vis sont freinées au Loctite bleu** par l'usine. Il faut exercer une pression ferme en vissant avant de tourner, sous peine d'arracher la tête de vis.

---

## Étapes de démontage

### 1. Déconnexion et refroidissement

1. **Éteignez** la gateway et débranchez le câble d'alimentation USB-C.
2. Attendez **2 minutes** que le Raspberry Pi refroidisse — le dissipateur thermique peut atteindre 60 °C en fonctionnement.
3. Débranchez le câble Ethernet s'il est connecté.

### 2. Retrait du couvercle supérieur

Le boîtier SenseCAP M1 est en aluminium anodisé gris. Le couvercle supérieur est maintenu par **4 vis Philips PH0** situées sous les 4 patins en caoutchouc du fond.

```
┌─────────────────────────────┐
│  [vis]            [vis]     │  ← fond du boîtier
│                             │
│  [vis]            [vis]     │
└─────────────────────────────┘
```

1. Retournez le boîtier.
2. Décolllez les **4 patins en caoutchouc** (ils se recollent sans problème).
3. Dévissez les 4 vis Philips PH0. **Astuce** : exercez une forte pression vers le bas tout en tournant pour ne pas arracher la tête freinée au Loctite.
4. Retournez le boîtier à l'endroit et soulevez le couvercle supérieur.

> ⚠️ Le connecteur d'antenne interne (U.FL vers SMA) est collé au couvercle. Soulevez lentement pour ne pas l'arracher.

### 3. Déconnexion de l'antenne interne

1. Repérez le câble coaxial fin reliant le module SX1302 au connecteur SMA externe.
2. Le connecteur U.FL côté module se déclipse en tirant perpendiculairement au PCB — utilisez un ongle ou un spudger plastique, **jamais de tournevis métallique**.

```
Connecteur U.FL :
     ┌──┐
 ════╡  ╞════  ← tirer vers le haut perpendiculairement
     └──┘
```

### 4. Localisation et extraction de la carte microSD

La carte microSD est insérée dans un slot push-push sous la carte mère du Raspberry Pi.

**Position** : côté gauche du PCB principal, vers l'arrière du boîtier (côté opposé aux ports USB).

```
Vue intérieure (couvercle retiré) :
┌────────────────────────────────────┐
│  [Ethernet] [USB-A] [USB-A] [USB-C]│
│                                    │
│  ┌──────────────────────────────┐  │
│  │  Raspberry Pi 4 / CM4        │  │
│  │                              │  │
│  │          [microSD] ◄─ ici    │  │
│  └──────────────────────────────┘  │
│  ┌────────────────┐                │
│  │ SX1302 mini-PCIe│               │
│  └────────────────┘                │
└────────────────────────────────────┘
```

1. Utilisez une pince à bec fin (ou brucelles) pour saisir la carte microSD par son extrémité.
2. Appuyez doucement vers l'intérieur (push) pour déclipser le mécanisme push-push.
3. La carte s'éjecte légèrement — retirez-la délicatement.

> 💡 **Conservation recommandée** : collez la microSD originale à l'intérieur du boîtier avec un morceau de scotch double-face ou de mousse adhésive. Elle contient l'image Helium d'origine qui permet de revendre ou restaurer l'appareil.

### 5. État après démontage

Vous devriez avoir :
- Le boîtier SenseCAP M1 ouvert avec le Raspberry Pi accessible
- La carte microSD originale retirée et mise de côté
- Le câble U.FL déconnecté

**Ne remontez pas encore** — passez à l'étape [02 — Flash du système](02-flash-systeme.md).

---

## Points d'attention

| Risque | Prévention |
|--------|------------|
| Vis arrachée (frein au Loctite) | Pression ferme, PH0 de qualité |
| Câble U.FL arraché | Traction perpendiculaire, jamais de levier |
| Dommages ESD | Déchargez-vous sur le boîtier métallique avant de toucher les PCB |
| Mise sous tension sans antenne | **Ne jamais alimenter sans antenne 868 MHz branchée sur le SMA** |
