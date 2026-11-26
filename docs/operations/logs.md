# Logs et diagnostic (staging / production)

Où trouver l'information quand quelque chose casse sur le VPS, du plus rapide au plus détaillé.

## 1. Erreurs applicatives : écran admin « Rapports de bug »

L'app enregistre elle-même ses pannes dans `BugReport` (`config/initializers/automatic_bug_reporting.rb`), regroupées par empreinte (classe d'exception + chemin) avec un compteur d'occurrences :

- erreur non gérée pendant une requête (500) et page introuvable (404) ;
- job en échec (SolidQueue, mails `deliver_later`…) une fois les `retry_on` épuisés : note « Erreur de job (…) : <ClasseDuJob> ».

C'est le premier endroit à regarder : message, extrait de backtrace, page, rôle de l'utilisateur.

## 2. Logs Rails et conteneurs : compte `logs` (lecture seule)

Depuis WSL, via l'hôte SSH `circographe-logs` (commande imposée `/usr/local/bin/circographe-logs`, source : `ops/vps/circographe-logs`) :

```bash
ssh -n circographe-logs staging              # 200 dernières lignes du conteneur en cours
ssh -n circographe-logs production 1000
ssh -n circographe-logs staging errors 2h    # ERROR/FATAL/exceptions/5xx depuis 2 h (défaut 1h)
ssh -n circographe-logs production since 30m # tout depuis 30 min, y compris avant le dernier déploiement
ssh -n circographe-logs staging grep /contact 1d
ssh -n circographe-logs staging request 3f2a1b4c-…   # toutes les lignes d'une requête (request_id)
ssh -n circographe-logs analytics 100        # Umami
ssh -n circographe-logs proxy 100            # kamal-proxy (tous les sites)
```

Chaque ligne Rails porte le `request_id` (staging et production, `log_tags`) : on part d'une erreur, on copie son id, puis `request <id>` donne toute la requête.

Les arguments sont validés strictement (durées `30m`/`2h`/`1d`, texte sans espace ni caractère spécial, 5000 lignes max). Le script n'écrit rien. Dans les dotfiles : `pro-applogs <arguments>`.

## 3. Où vivent les logs sur le VPS

Les conteneurs de l'app (`logging:` dans `config/deploy.staging.yml` / `deploy.production.yml`) et d'Umami (`docker/analytics/docker-compose.yml`) écrivent dans le **journal du système** (driver Docker `journald`), avec un tag fixe :

| Tag journald | Conteneur |
| --- | --- |
| `circographe-staging` | app staging |
| `circographe-production` | app production |
| `umami`, `umami-db` | analytics |

Le journal est persistant (`/var/log/journal`) : les logs survivent aux déploiements (Kamal supprime les anciens conteneurs, et avec eux leurs logs `json-file`) et aux redémarrages. `docker logs` continue de fonctionner sur le conteneur en cours. En root ou `deploy` avec le groupe adéquat : `journalctl -t circographe-staging --since "-2h"`.

`kamal-proxy` reste en `json-file` (10 Mo) : changer son driver demande un `kamal proxy reboot`, donc une fenêtre de maintenance (voir `deployment.md`).

## 4. Mise en place sur le VPS (root, une fois)

D'abord, avec le compte deploy, mettre à jour la copie des outils (sinon `install` ne trouve pas le script) :

```bash
ssh -n circographe-deploy 'cd ~/circographe-tools && git pull --ff-only'
```

Puis, par un humain avec `circographe-root`. Après chaque modification de `ops/vps/circographe-logs`, refaire ce `git pull` puis la seule ligne `install` :

```bash
# script de lecture des logs (remplace l'ancienne version)
install -o root -g root -m 755 /home/deploy/circographe-tools/ops/vps/circographe-logs /usr/local/bin/circographe-logs
# le compte logs doit pouvoir lire le journal
usermod -aG systemd-journal logs
# journal sur disque (Storage=persistent : sinon, sans /var/log/journal, journald garde tout en RAM
# et perd les logs au redémarrage), plafond et durée de rétention (les logs contiennent des chemins
# et des IP : pas plus d'un mois)
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nStorage=persistent\nSystemMaxUse=2G\nMaxRetentionSec=1month\n' > /etc/systemd/journald.conf.d/circographe.conf
systemctl restart systemd-journald
# doit afficher /var/log/journal/<machine-id> et sa taille
journalctl --disk-usage
```

Puis :

- **app** : le driver `journald` s'applique au prochain `kamal deploy` (staging : promotion habituelle ; production : après la réconciliation) ;
- **Umami** : `cd ~/circographe-tools/docker/analytics && docker compose up -d` (recrée les deux conteneurs, ~30 s de coupure d'analytics).

Vérifier : `ssh -n circographe-logs staging since 10m` doit afficher des lignes horodatées au format ISO (signe que le journal est lu).
