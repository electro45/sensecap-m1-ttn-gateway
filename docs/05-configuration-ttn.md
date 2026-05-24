# 05 — Configuration sur The Things Network (TTN)

## Objectif

Enregistrer la gateway SenseCAP M1 sur la console TTN Community Edition, la configurer pour qu'elle pointe vers le serveur EU1 de TTN, et la rendre publique pour contribuer à la couverture LoRaWAN communautaire.

---

## Architecture de connexion

```
Objets LoRaWAN (End devices)
         │  RF 868 MHz
         ▼
┌────────────────────┐
│  SenseCAP M1       │
│  SX1302 + SX1250   │
│  Raspberry Pi 4    │
│  lora_pkt_fwd      │
└────────┬───────────┘
         │  UDP :1700 (PUSH_DATA / PULL_DATA)
         ▼
eu1.cloud.thethings.network:1700
         │
         ▼
TTN Network Server → Application Server → vos applications
```

Le **Semtech UDP Packet Forwarder** (UDP port 1700) est le protocole de communication entre la gateway et TTN. Il ne chiffre pas les communications (le chiffrement LoRaWAN est end-to-end au niveau applicatif).

---

## Étape 1 : Récupérer l'EUI de la gateway

Si ce n'est pas déjà fait lors de l'étape 04, lancez le forwarder une première fois pour obtenir l'EUI :

```bash
cd /opt/sx1302_hal/packet_forwarder
sudo ./lora_pkt_fwd 2>&1 | grep -i "EUI"
```

Exemple de sortie :

```
INFO: concentrator EUI: 0x58A0CBFFFE123456
```

**Notez l'EUI au format `58A0CBFFFE123456`** (sans le préfixe `0x`).

---

## Étape 2 : Créer un compte TTN et accéder à la console

1. Rendez-vous sur [console.cloud.thethings.network](https://console.cloud.thethings.network/).
2. Sélectionnez le cluster **Europe 1** (eu1).
3. Connectez-vous ou créez un compte gratuit.
4. Dans le menu gauche, cliquez sur **Gateways**.

---

## Étape 3 : Enregistrer la gateway

1. Cliquez **+ Register gateway** (ou **Enregistrer une gateway**).

2. Remplissez le formulaire :

| Champ | Valeur |
|-------|--------|
| **Gateway EUI** | L'EUI récupéré ci-dessus (ex: `58A0CBFFFE123456`) |
| **Gateway ID** | `sensecap-m1-eu868` (ou votre choix, minuscules + tirets) |
| **Gateway name** | `SenseCAP M1 EU868` |
| **Frequency plan** | `Europe 863-870 MHz (SF9 for RX2 - recommended)` |
| **Gateway Server address** | `eu1.cloud.thethings.network` |

3. Cliquez **Register gateway**.

---

## Étape 4 : Rendre la gateway publique (Share Coverage)

Pour contribuer à la couverture communautaire TTN (et apparaître sur la carte TTN Mapper) :

1. Depuis la page de votre gateway → onglet **General settings**.
2. Section **Location** : entrez vos coordonnées GPS (latitude, longitude, altitude).
3. Section **Privacy** : cochez **Share location** et **Share status**.

> En cochant "Share status", votre gateway sera visible dans le [TTN Mapper](https://ttnmapper.org/) et contribue aux données de couverture publiques.

---

## Étape 5 : Configurer le fichier global_conf.json

Le fichier `/etc/sx1302_ttn/global_conf.json` doit pointer vers le serveur TTN EU1. Vérifiez (ou modifiez) la section `gateway_conf` :

```bash
sudo nano /etc/sx1302_ttn/global_conf.json
```

Section à vérifier :

```json
"gateway_conf": {
    "gateway_ID": "AA555A0000000000",
    "server_address": "eu1.cloud.thethings.network",
    "serv_port_up": 1700,
    "serv_port_down": 1700,
    "keepalive_interval": 10,
    "stat_interval": 30,
    "push_timeout_ms": 100,
    "forward_crc_valid": true,
    "forward_crc_error": false,
    "forward_crc_disabled": false
}
```

> ⚠️ Le champ `gateway_ID` **n'est pas automatiquement écrasé** par le forwarder — il utilise la valeur du fichier telle quelle. Le placeholder `AA555A0000000000` doit être remplacé par l'EUI réel du concentrateur (voir étape 04), sinon la gateway restera rouge dans la console TTN même si le forwarder reçoit des PUSH_ACK de TTN.

---

## Étape 6 : Test de connexion

Lancez le forwarder manuellement et observez les logs :

```bash
sudo lora_pkt_fwd -c /etc/sx1302_ttn/global_conf.json
```

Attendez 30 secondes et vérifiez les lignes suivantes :

```
INFO: [TTN] concentrator started, packet can now be received
INFO: [main] concentrator EUI: 0x58A0CBFFFE123456
INFO: [up] PUSH_ACK received in 45 ms (1) for server eu1.cloud.thethings.network
INFO: [down] PULL_ACK received in 46 ms (1) for server eu1.cloud.thethings.network
```

### Vérification dans la console TTN

1. Retournez sur [console.cloud.thethings.network](https://console.cloud.thethings.network/).
2. Cliquez sur votre gateway → onglet **Overview**.
3. Le statut doit passer au **vert** avec "Connected" et "Last seen: a few seconds ago".

---

## Dépannage

### Gateway reste "Never seen" ou "Disconnected"

- Vérifiez que le port UDP **1700** est ouvert en sortie sur votre routeur/firewall.
- Testez la connectivité UDP : `nc -u eu1.cloud.thethings.network 1700` (Ctrl+C après 2 sec).
- Vérifiez les logs du forwarder pour des erreurs `PUSH_NAK` ou timeouts.

### Erreur "Invalid EUI" lors de l'enregistrement

L'EUI doit être en majuscules, sans `0x`, sans tirets ni espaces : `58A0CBFFFE123456`.

### Le forwarder se déconnecte régulièrement

Vérifiez la stabilité de votre connexion Internet et l'alimentation USB-C (courant insuffisant = instabilité).

---

## Étape suivante

Passez à [06 — Tests et vérification](06-tests-verification.md).
