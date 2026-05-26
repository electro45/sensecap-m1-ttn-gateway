# 08 — ChirpStack v4 (réseau LoRaWAN privé local)

## Objectif

Accéder à l'interface ChirpStack pour enregistrer vos propres capteurs LoRaWAN et visualiser leurs trames, indépendamment de TTN.

---

## Architecture installée

```
lora_pkt_fwd
     │ UDP :1700
     ▼
packet-multiplexer
     ├──→ TTN eu1.cloud.thethings.network:1700
     └──→ chirpstack-gateway-bridge :1701
               │ MQTT (topics eu868/gateway/...)
               ▼
          mosquitto :1883
               │
               ▼
          chirpstack ─── postgresql ─── redis
               │
               ▼
        Interface web :8080
```

---

## Étape 1 : Première connexion à ChirpStack

Une fois `setup-chirpstack.sh` exécuté, ouvrez un navigateur sur le réseau local :

```
http://<IP-de-la-gateway>:8080
```

Identifiants par défaut :

| Champ | Valeur |
|-------|--------|
| **Login** | `admin` |
| **Mot de passe** | `admin` |

> ⚠️ Changez le mot de passe admin immédiatement après la première connexion.

---

## Étape 2 : Vérifier que la gateway apparaît dans ChirpStack

1. Menu → **Gateways**
2. Votre gateway doit apparaître avec le statut **Online** (vert).

Si la gateway est absente ou offline :

```bash
# Vérifier le Gateway Bridge
sudo journalctl -u chirpstack-gateway-bridge -n 30

# Vérifier que le bridge reçoit des trames sur :1701
sudo ss -ulnp | grep 1701
```

---

## Étape 3 : Enregistrer une application et un capteur

### Créer un profil de device

1. Menu → **Device profiles** → **Add device profile**
2. Choisissez :
   - **Region** : `EU868`
   - **MAC version** : selon votre capteur (LoRaWAN 1.0.x ou 1.1.x)
   - **Regional parameters** : `RP002-1.0.3`
3. Sauvegardez.

### Créer une application

1. Menu → **Applications** → **Add application**
2. Donnez un nom (ex: `mes-capteurs`).

### Enregistrer un capteur (OTAA)

1. Dans l'application → **Add device**
2. Renseignez :
   - **Device EUI** : l'EUI-64 de votre capteur (au dos ou dans sa doc)
   - **Device profile** : celui créé ci-dessus
   - **Application key** (AppKey) : fournie par le fabricant ou générée
3. Mettez le capteur en mode d'appairage (reset ou bouton join).

---

## Étape 4 : Visualiser les trames

Une fois le capteur appairé :

1. Application → votre capteur → onglet **Events**
2. Vous voyez en temps réel les `up` (uplinks), `join`, `ack`.
3. Onglet **LoRaWAN frames** : trames brutes (PHYPayload décodé).

---

## Services et logs

| Service | Rôle | Logs |
|---------|------|------|
| `packet-multiplexer` | Distribue les trames | `journalctl -u packet-multiplexer -f` |
| `chirpstack-gateway-bridge` | Convertit UDP→MQTT | `journalctl -u chirpstack-gateway-bridge -f` |
| `mosquitto` | Bus MQTT | `journalctl -u mosquitto -f` |
| `chirpstack` | Network Server + App Server | `journalctl -u chirpstack -f` |
| `postgresql` | Base de données | `journalctl -u postgresql -f` |
| `redis-server` | Cache sessions | `journalctl -u redis-server -f` |

---

## Dépannage

### La gateway est "Never seen" dans ChirpStack

Vérifiez l'ordre des services et les connexions :

```bash
# 1. Le multiplexeur reçoit-il les trames du forwarder ?
sudo journalctl -u packet-multiplexer -n 20 | grep -i "uplink\|push\|received"

# 2. Le Gateway Bridge reçoit-il sur :1701 ?
sudo journalctl -u chirpstack-gateway-bridge -n 20

# 3. MQTT reçoit-il des messages ?
mosquitto_sub -h 127.0.0.1 -t "eu868/gateway/+/event/+" -v &
# Attendu : des topics avec l'EUI de votre gateway
```

### Erreur "no device-profile found" lors du join

Le profil de device n'est pas correctement associé à l'application. Vérifiez la **Region** (`EU868`) dans le profil.

### Mot de passe admin oublié

```bash
sudo chirpstack -c /etc/chirpstack/chirpstack.toml create-api-key --name admin-recovery
```

---

## Ressources

- [Documentation ChirpStack v4](https://www.chirpstack.io/docs/chirpstack/)
- [ChirpStack Gateway Bridge](https://www.chirpstack.io/docs/chirpstack-gateway-bridge/)
