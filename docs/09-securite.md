# 09 — Durcissement sécurité

## Objectif

Appliquer les mesures de sécurité essentielles après l'installation : révoquer les accès trop permissifs, protéger les services internes et renforcer l'accès SSH.

---

## Prérequis

- Avoir une **clé SSH publique** déposée sur le Pi avant de lancer ce script, sinon l'étape SSH sera ignorée (vous ne pourrez plus vous connecter si vous bloquez les mots de passe sans clé) :

```bash
# Depuis votre machine locale
ssh-copy-id -i ~/.ssh/id_ed25519.pub gateway@<IP-de-la-gateway>
```

---

## Lancer le script de durcissement

```bash
sudo bash scripts/harden.sh
```

---

## Ce que fait le script

### Étape 1 — Révocation du sudo NOPASSWD

Le script `install.sh` configure `gateway ALL=(ALL) NOPASSWD: ALL` pour simplifier l'installation. Une fois en production, cet accès est supprimé : toute commande `sudo` demandera le mot de passe utilisateur.

### Étape 2 — Authentification Redis

Redis n'est pas authentifié par défaut. Le script génère un mot de passe aléatoire et le configure dans `/etc/redis/redis.conf` et dans `/etc/chirpstack/chirpstack.toml`.

### Étape 3 — SSH par clé uniquement

Si une clé SSH est présente dans `~/.ssh/authorized_keys` :

- `PasswordAuthentication no` — plus d'accès par mot de passe
- `PermitRootLogin no` — connexion root SSH interdite

> ⚠️ Si aucune clé n'est trouvée, cette étape est ignorée. Relancez `harden.sh` après avoir déposé votre clé.

### Étape 4 — fail2ban

Installe et configure fail2ban pour bannir automatiquement les IP après 5 tentatives de connexion SSH échouées (durée : 1 heure).

---

## Action manuelle requise

### Changer le mot de passe admin ChirpStack

Le mot de passe par défaut `admin` doit être changé immédiatement après la première connexion :

1. Ouvrez `http://<IP>:8080`
2. Connectez-vous avec `admin` / `admin`
3. Cliquez sur votre profil (en haut à droite) → **Change password**

---

## Vérifications post-durcissement

```bash
# Tester la connexion SSH par clé (depuis votre machine)
ssh -o PasswordAuthentication=no gateway@<IP>
# Attendu : connexion réussie sans saisie de mot de passe

# Vérifier fail2ban
sudo fail2ban-client status sshd

# Vérifier Redis avec auth
redis-cli -a <votre-mot-de-passe> ping
# Attendu : PONG

# Vérifier que sudo demande bien un mot de passe
sudo ls
# Attendu : demande du mot de passe utilisateur
```

---

## Récapitulatif sécurité

| Mesure | Statut après harden.sh |
|--------|------------------------|
| Sudo NOPASSWD | ✅ Révoqué |
| Redis authentifié | ✅ Mot de passe aléatoire |
| SSH auth par mot de passe | ✅ Désactivé (si clé présente) |
| Root login SSH | ✅ Interdit |
| fail2ban | ✅ Actif (5 essais → 1h de ban) |
| Mot de passe admin ChirpStack | ⚠️ À changer manuellement |
| HTTPS ChirpStack | ℹ️ Non configuré (LAN uniquement) |
