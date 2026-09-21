# Backup & restauration — production

> **Statut** : internal — équipe dev/infra
> **Scope** : production uniquement. Staging est volontairement volatile (`reset_db`,
> reseed à chaque usage — voir `config/deploy.staging.yml`) et n'est pas sauvegardée.

## Architecture

Pas de container base de données séparé : SQLite est un fichier, il vit dans le même
container Kamal que Rails, sur le volume Docker `circographe_production_storage`
(`/rails/storage`). Ce volume contient à la fois les fichiers SQLite et les fichiers
Active Storage (galerie, logos CA/partenaires, avatars).

Deux mécanismes indépendants, pas redondants entre eux :

| | Couvre | Fréquence | Destination |
|---|---|---|---|
| **Litestream** (gem `litestream`, plugin Puma) | `storage/production.sqlite3` uniquement | Continu (quasi temps réel) | IONOS Object Storage (S3-compatible) |
| **`Backups::NightlySnapshotJob`** (SolidQueue recurring) | `production.sqlite3` (copie sûre) + tous les fichiers Active Storage | Nocturne (3h) | pCloud (via `rclone`) |

`production_cache.sqlite3`, `production_queue.sqlite3` et `production_cable.sqlite3` ne
sont **pas** sauvegardés : cache régénérable, queue de jobs éphémère, pub/sub Action
Cable sans donnée persistante — aucune perte réelle, ça évite de répliquer du bruit.

## Setup initial (une fois)

### 1. IONOS Object Storage

1. Espace client IONOS Cloud → créer une ressource **Object Storage** + un bucket
   (ex. `circographe-backups`).
2. Générer une clé d'accès S3 (access key + secret key).
3. Noter aussi l'**endpoint** et la **région** du bucket (visibles dans le panneau IONOS,
   ex. `s3.eu-central-3.ionoscloud.com` / `eu-central-3`).
4. Remplir les credentials Rails :

   ```
   bin/rails credentials:edit
   ```

   ```yaml
   litestream:
     replica_bucket: circographe-backups
     replica_region: eu-central-3
     replica_endpoint: s3.eu-central-3.ionoscloud.com
     replica_key_id: <access-key>
     replica_access_key: <secret-key>
     dashboard_username: admin
     dashboard_password: <mot-de-passe-dashboard-litestream>
   ```

### 2. pCloud (rclone)

Le flow OAuth est interactif (navigateur) — à faire **en local**, pas sur le serveur.

```
rclone config
# n) New remote → name: pcloud → Storage: Pcloud → suivre le flow OAuth
#   (choisir la région EU dans le compte pCloud avant de générer le token
#   si vous voulez garder les données en Europe)
```

Une fois configuré, le fichier `~/.config/rclone/rclone.conf` contient un remote nommé
`pcloud` avec un refresh token OAuth.

Créer l'arborescence sur pCloud avant le premier run :
```
rclone mkdir "pcloud:DevOps/circographe-backups/production"
rclone mkdir "pcloud:DevOps/circographe-backups/staging-test"
```
`staging-test` sert uniquement aux tests manuels `rclone` sur staging (NightlySnapshotJob
ne tourne jamais sur staging — voir la garde `production?` dans le service) — à ne pas
confondre avec `production`, géré automatiquement (upload + purge des fichiers > 14 jours).

#### Chiffrement au repos (`crypt`)

L'OAuth pCloud donne accès à tout le compte, sans scope par dossier (contrairement à
Dropbox App Folder). Pour ne pas exposer les données membres/paiements en clair en cas de
fuite des credentials, on chiffre côté client avant l'upload avec un remote `crypt`
empilé sur `pcloud` :

```
rclone config
# n) New remote → name: pcloud-crypt → Storage: crypt
# remote> pcloud:DevOps/circographe-backups
# filename encryption> standard
# directory name encryption> true
# password / password2 (salt)> laisser rclone générer les deux
```

Les deux mots de passe générés sont affichés **une seule fois** — à stocker immédiatement
dans un gestionnaire de mots de passe. Sans eux, le contenu chiffré sur pCloud est
définitivement irrécupérable (c'est le but). Le service `Backups::NightlySnapshotService`
pousse vers `pcloud-crypt:production` (voir `RCLONE_REMOTE`) ; les noms de fichiers et
dossiers réels sur pCloud sont illisibles sans passer par le remote `pcloud-crypt`.

Le `rclone.conf` final contient donc deux sections (`[pcloud]` avec le token OAuth et
`[pcloud-crypt]` avec les mots de passe chiffrés) — c'est ce fichier complet qui doit être
déployé sur le serveur à `/rails/.config/rclone/rclone.conf` côté container (hors dépôt
git — à transmettre via un secret Kamal ou un montage de fichier, pas committé en clair).

## Vérification (à faire avant de considérer le backup opérationnel)

- **Litestream réplique** : après déploiement, `bin/kamal app logs -c config/deploy.production.yml`
  et chercher les lignes de Litestream (pas d'erreur de credentials/endpoint). Le bucket
  IONOS doit voir apparaître des objets peu après le premier boot.
- **Restauration testée réellement** (todo historique : *« prod jamais testé = cassé »* —
  ne pas cocher tant que ce test n'a pas été fait pour de vrai) :

  ```
  bin/kamal app exec -c config/deploy.production.yml --reuse \
    "bin/rails litestream:restore -- -database=/tmp/test_restore.sqlite3"
  ```

  Vérifier que `/tmp/test_restore.sqlite3` est un fichier SQLite valide et cohérent
  (`sqlite3 /tmp/test_restore.sqlite3 "SELECT COUNT(*) FROM people;"` ou équivalent).
- **Snapshot nocturne testé manuellement** :

  ```
  bin/kamal app exec -c config/deploy.production.yml --reuse \
    "bin/rails runner 'puts Backups::NightlySnapshotJob.perform_now.inspect'"
  ```

  Puis vérifier l'apparition du fichier daté dans le dossier pCloud.

## Restauration réelle (disaster recovery)

Le cas volume perdu/VPS recréé est géré automatiquement par `bin/docker-entrypoint` :
si `storage/production.sqlite3` est absent au boot en production, une restauration
Litestream est lancée avant `db:prepare`. Pas d'action manuelle nécessaire dans ce cas —
juste redéployer normalement sur un nouveau volume/serveur.

Pour une restauration ciblée (erreur humaine, pas perte du volume) : utiliser
`litestream:restore` vers un fichier temporaire, vérifier son contenu, puis remplacer
manuellement `storage/production.sqlite3` (jamais en écrasant à l'aveugle sans avoir
vérifié la copie restaurée d'abord).

## Hors scope de ce mécanisme

- Pas de bascule d'Active Storage vers un stockage S3-natif pour l'instant (cold start,
  rien à migrer) — différé à un vrai lancement avec de vraies données membres.
- Pas de sauvegarde staging (volatile par design).
