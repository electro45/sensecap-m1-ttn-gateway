# 06 — Tests et vérification bout en bout

## Objectif

Valider que la gateway est opérationnelle : statut vert dans TTN, réception de trames LoRaWAN, et activation du service systemd pour un démarrage automatique.

---

## Étape 1 : Vérification du statut dans la console TTN

### 1a — Statut de connexion

1. Ouvrez [console.cloud.thethings.network](https://console.cloud.thethings.network/).
2. Menu **Gateways** → sélectionnez votre gateway.
3. Onglet **Overview**.

Résultat attendu :

```
Statut :    ● Connectée (vert)
Last seen : il y a quelques secondes
```

Si le statut est orange ou rouge, relisez [05 — Configuration TTN](05-configuration-ttn.md) section dépannage.

### 1b — Trafic en temps réel

1. Onglet **Live data** (ou "Données en direct").
2. Des paquets doivent apparaître si des objets LoRaWAN sont à portée.

Exemple de trame reçue :

```json
{
  "name": "gs.gateway.receive",
  "time": "2024-01-15T14:32:10.123Z",
  "identifiers": [{"gateway_ids": {"gateway_id": "sensecap-m1-eu868"}}],
  "data": {
    "@type": "type.googleapis.com/ttn.lorawan.v3.UplinkMessage",
    "raw_payload": "QJg...",
    "rx_metadata": [{
      "gateway_ids": {"gateway_id": "sensecap-m1-eu868"},
      "rssi": -87,
      "channel_rssi": -87,
      "snr": 9.5
    }]
  }
}
```

---

## Étape 2 : Vérification des logs du forwarder

Lancez le forwarder en mode verbeux pour observer le trafic en temps réel :

```bash
sudo lora_pkt_fwd -c /etc/sx1302_ttn/global_conf.json
```

### Logs normaux attendus

```
##### 2024-01-15 14:32:00 GMT #####
### [UPSTREAM] ###
# RF packets received by concentrator: 3
# CRC_OK: 100.00%, CRC_FAIL: 0.00%, NO_CRC: 0.00%
# RF packets forwarded: 3 (142 bytes)
# PUSH_DATA datagrams sent: 2 (508 bytes)
# PUSH_DATA acknowledged: 100.00%
### [DOWNSTREAM] ###
# PULL_DATA sent: 3 (100.00% acknowledged)
# PULL_RESP(onse) datagrams received: 0 (0 bytes)
# RF packets sent to concentrator: 0 (0 bytes)
### [JIT] ###
# [jit] queue length: 0
### [GPS] ###
# GPS sync is disabled
```

Les métriques clés :
- `PUSH_DATA acknowledged: 100.00%` → connexion TTN stable
- `CRC_OK: 100.00%` → réception radio correcte
- `RF packets received` > 0 → des objets LoRaWAN sont à portée

---

## Étape 3 : Installation du service systemd

Le service systemd permet au forwarder de démarrer automatiquement au boot et de redémarrer en cas de plantage.

### 3a — Copier le fichier service

```bash
sudo cp /chemin/vers/sensecap-m1-ttn-gateway/systemd/sx1302_forwarder.service \
        /etc/systemd/system/sx1302_forwarder.service
```

### 3b — Activer et démarrer le service

```bash
# Recharger les définitions systemd
sudo systemctl daemon-reload

# Activer le service au démarrage
sudo systemctl enable sx1302_forwarder.service

# Démarrer le service immédiatement
sudo systemctl start sx1302_forwarder.service
```

### 3c — Vérifier le statut du service

```bash
sudo systemctl status sx1302_forwarder.service
```

Résultat attendu :

```
● sx1302_forwarder.service - LoRaWAN SX1302 Packet Forwarder (TTN)
     Loaded: loaded (/etc/systemd/system/sx1302_forwarder.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-15 14:30:00 UTC; 2min 35s ago
   Main PID: 1234 (lora_pkt_fwd)
      Tasks: 7 (limit: 4915)
     Memory: 4.5M
        CPU: 0.234s
     CGroup: /system.slice/sx1302_forwarder.service
             └─1234 /usr/local/bin/lora_pkt_fwd -c /etc/sx1302_ttn/global_conf.json

Jan 15 14:30:02 sensecap-gw lora_pkt_fwd[1234]: INFO: concentrator EUI: 0x58A0CBFFFE123456
Jan 15 14:30:03 sensecap-gw lora_pkt_fwd[1234]: INFO: concentrator started, packet can now be received
```

---

## Étape 4 : Test de redémarrage

Redémarrez le Pi pour valider que le service démarre automatiquement :

```bash
sudo reboot
```

Après reconnexion SSH (attendre ~60 secondes) :

```bash
sudo systemctl status sx1302_forwarder.service
# Doit afficher : Active: active (running)

# Vérifier les logs de démarrage
sudo journalctl -u sx1302_forwarder.service -n 50
```

---

## Étape 5 : Consulter les logs en temps réel

```bash
# Suivre les logs en temps réel
sudo journalctl -u sx1302_forwarder.service -f

# Logs des 24 dernières heures
sudo journalctl -u sx1302_forwarder.service --since "24 hours ago"
```

---

## Étape 6 : Vérification de la couverture (optionnel)

Pour tester la portée de votre gateway et contribuer à la carte de couverture communautaire :

1. Installez [TTN Mapper](https://ttnmapper.org/) sur votre smartphone.
2. Connectez un objet LoRaWAN à votre application TTN.
3. Promener l'objet à différentes distances et l'application cartographie automatiquement la couverture.

---

## Résumé de l'installation

| Composant | Statut |
|-----------|--------|
| Raspberry Pi OS Lite 64-bit | ✓ Installé |
| I2C, SPI, UART activés | ✓ Configurés |
| sx1302_hal compilé | ✓ `/usr/local/bin/lora_pkt_fwd` |
| Configuration TTN EU868 | ✓ `/etc/sx1302_ttn/global_conf.json` |
| Service systemd | ✓ Activé et démarrage automatique |
| Gateway TTN | ✓ Connectée (statut vert) |

---

## Commandes utiles au quotidien

```bash
# Statut du service
sudo systemctl status sx1302_forwarder

# Redémarrer le forwarder
sudo systemctl restart sx1302_forwarder

# Arrêter le forwarder
sudo systemctl stop sx1302_forwarder

# Logs en temps réel
sudo journalctl -u sx1302_forwarder -f

# Température du Pi (surveillance thermique)
vcgencmd measure_temp
```

---

Votre **SenseCAP M1 est désormais une gateway LoRaWAN publique TTN opérationnelle**. Elle reçoit les trames des objets LoRaWAN à portée et les remonte vers le réseau TTN, contribuant à la couverture communautaire.

---

## Étape suivante (optionnelle)

Pour ajouter un réseau **ChirpStack privé local** en parallèle de TTN (sans rien changer à la configuration TTN) :

Passez à [07 — Packet Multiplexer](07-packet-multiplexer.md).
