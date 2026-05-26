# 07 — Packet Multiplexer (TTN + ChirpStack en parallèle)

## Objectif

Faire recevoir les trames LoRaWAN par **TTN et ChirpStack simultanément**, sans modifier le packet forwarder ni choisir entre les deux réseaux.

---

## Pourquoi un multiplexeur ?

`lora_pkt_fwd` ne peut pointer que vers **un seul serveur UDP**. Le packet multiplexer s'intercale entre le forwarder et les deux réseaux : il reçoit chaque trame une seule fois et la retransmet en parallèle.

```
lora_pkt_fwd
     │ UDP 1700 → localhost (multiplexeur)
     ▼
packet-multiplexer :1700
     ├──→ eu1.cloud.thethings.network:1700   (TTN, inchangé)
     └──→ localhost:1701                      (ChirpStack Gateway Bridge)
```

---

## Étape 1 : Exécuter le script d'installation

Le script `setup-chirpstack.sh` installe le multiplexeur, ChirpStack et reconfigure automatiquement le forwarder :

```bash
cd /chemin/vers/sensecap-m1-lorawan-gateway
sudo bash scripts/setup-chirpstack.sh
```

> Le script installe en une seule passe : packet-multiplexer, chirpstack-gateway-bridge, mosquitto, postgresql, redis et chirpstack.

---

## Étape 2 : Vérifier le multiplexeur

```bash
sudo systemctl status packet-multiplexer
sudo journalctl -u packet-multiplexer -n 30
```

Sortie attendue :

```
INFO packet_multiplexer: starting, bind=0.0.0.0:1700
INFO packet_multiplexer: backend connected, host=eu1.cloud.thethings.network:1700
INFO packet_multiplexer: backend connected, host=127.0.0.1:1701
```

---

## Étape 3 : Vérifier que TTN reste connectée

La gateway doit rester **verte** dans la console TTN après l'installation :

1. Rendez-vous sur [console.cloud.thethings.network](https://console.cloud.thethings.network/).
2. Votre gateway → onglet **Overview** → statut **Connected**.

Si la gateway passe rouge, vérifiez que le multiplexeur est bien démarré et que `global_conf.json` pointe vers `127.0.0.1` :

```bash
grep "server_address" /etc/sx1302_ttn/global_conf.json
# Attendu : "server_address": "127.0.0.1"
```

---

## Configuration du multiplexeur

Le fichier de configuration se trouve dans `/etc/chirpstack-pktmux/packet-multiplexer.toml`. Pour ajouter ou retirer un backend :

```toml
[multiplexer]
bind = "0.0.0.0:1700"

  [[multiplexer.backends]]
  host = "eu1.cloud.thethings.network:1700"   # TTN EU1

  [[multiplexer.backends]]
  host = "127.0.0.1:1701"                      # ChirpStack Gateway Bridge
```

Après modification, redémarrez le service :

```bash
sudo systemctl restart packet-multiplexer
```

---

## Dépannage

### Le multiplexeur ne démarre pas

```bash
sudo journalctl -u packet-multiplexer -n 50
```

Vérifiez que le port 1700 n'est plus utilisé par le forwarder directement :

```bash
ss -ulnp | grep 1700
# Attendu : packet-mu sur :1700
```

### La gateway TTN est rouge après installation

Le `global_conf.json` doit pointer vers `127.0.0.1`, pas vers `eu1.cloud.thethings.network`. Le script le modifie automatiquement ; vérifiez manuellement si le problème persiste :

```bash
sudo grep "server_address" /etc/sx1302_ttn/global_conf.json
# Si toujours eu1.cloud.thethings.network :
sudo sed -i 's/"server_address": "eu1.cloud.thethings.network"/"server_address": "127.0.0.1"/' \
    /etc/sx1302_ttn/global_conf.json
sudo systemctl restart sx1302_forwarder
```

---

## Étape suivante

Passez à [08 — Installation de ChirpStack v4](08-chirpstack.md).
