# Images staging / production en local (Docker)

Lancer sur son poste **l'image exacte** qui tourne (ou a tourné) en staging ou en production, pour reproduire un bug lié au build (gems, assets, Ruby, configuration `staging`/`production`) que `bin/dev` ne montre pas. Ce n'est pas l'environnement de développement : `bin/dev` reste la norme pour coder.

Fichiers : `docker/local/compose.yml` (deux services à profils `staging` / `production` + un proxy Caddy) et `bin/docker-local`.

## Prérequis (une fois)

1. **Docker Desktop** lancé, avec l'intégration WSL activée pour la distro : *Settings → Resources → WSL integration → Ubuntu-26.04*, puis *Apply & restart*. Sans elle, `docker` dans WSL n'est qu'un raccourci vers `docker.exe` : `compose ps/exec` échouent et les variables d'environnement ne passent pas. Le script le vérifie.
2. **Accès aux images ghcr** (privées) : le token `gh` doit avoir le droit `read:packages`.
   ```bash
   gh auth refresh -s read:packages
   bin/docker-local login
   ```
3. `config/master.key` présent (comme pour `bin/dev`).

## Utilisation

```bash
bin/docker-local pull staging                # dernière image staging (tag latest)
bin/docker-local pull staging running        # l'image que le VPS fait tourner en ce moment (via ssh circographe-deploy)
bin/docker-local pull production <sha>       # une image précise
bin/docker-local up staging                  # http://127.0.0.1:8081 (basic auth staging / local)
bin/docker-local admin staging               # créer le premier super-admin
bin/docker-local logs staging
bin/docker-local console staging
bin/docker-local down staging --reset        # arrêter et repartir d'une base neuve au prochain up
bin/docker-local status
bin/docker-local build                       # image staging construite depuis ta copie de travail (tag local)
bin/docker-local upgrade                     # répétition de montée de version (voir plus bas)
```

Cold start de ta branche, avant tout push : `bin/docker-local build`, `bin/docker-local down staging --reset`, puis `bin/docker-local up staging`.

Production : `http://127.0.0.1:8082`, mode maintenance désactivé. Le tag choisi est mémorisé dans `docker/local/.env.local` (généré au premier lancement, permissions 600, git-ignoré : il contient la master key).

## Données

Chaque environnement démarre sur **sa propre base SQLite neuve** (volume Docker `circographe-local_<env>_storage`) : l'entrypoint de l'image lance `db:prepare` et donc les seeds du profil (`SEED_LEAN` en staging, contenu seul en production). **Rien n'est copié depuis le VPS**, et la base de production ne doit jamais l'être (données personnelles des adhérents).

## Répéter une montée de version (`upgrade`)

Sur le VPS, Kamal ne fait jamais de cold start : il démarre l'image N+1 **sur la base de l'image N**, et c'est là que les données cassent (migration qui échoue ou détruit des lignes, code qui suppose un état que la base n'a pas). Les images staging étant construites au moment du déploiement, il faut répéter **avant** de pousser sur `staging` :

```bash
bin/docker-local upgrade                     # image du VPS (running) → ta copie de travail (local)
bin/docker-local upgrade <sha> local         # depuis une image précise
bin/docker-local upgrade running latest      # après coup : ce qui vient d'être déployé
```

1. Base neuve + **données de démo riches** (`SEED_DEMO=true` : environ 140 personnes, 180 paiements, adhésions, cotisations, présences) sur l'image de départ.
2. Rapport de données (`ops/data_report.rb`) : lignes par table, `PRAGMA integrity_check` / `foreign_key_check`, règles de [`domain/data_integrity_rules.md`](../domain/data_integrity_rules.md) (comptes sans personne, paiements dont les lignes ne font pas le total, dons legacy `item_type: "Payment"`, cotisations pack10 sans séances…).
3. Image d'arrivée sur **le même volume** : son entrypoint lance les migrations, comme un `kamal deploy`.
4. Nouveau rapport, comparé : **échec** si une table perd des lignes ou disparaît avec des données, si une anomalie apparaît ou augmente, ou si SQLite signale une corruption. Nouvelles tables et nouvelles lignes sont normales.

Projet Docker séparé (`circographe-upgrade`, sans proxy) : ton staging local n'est pas touché. En cas de succès tout est supprimé ; en cas d'échec le conteneur est gardé pour inspection (`bin/docker-local upgrade-clean` ensuite). Rapports et logs : `tmp/docker-local/upgrade-<date>/`. Le script de rapport est copié dans le conteneur : il marche aussi sur une image qui ne le contient pas encore. Il est écrit en SQL pur : si une table ou une colonne qu'il lit est renommée, `spec/ops/data_report_spec.rb` échoue jusqu'à ce qu'on l'adapte.

Ce que ça ne couvre pas : les données réelles (on ne copie jamais la prod en local). Les démos couvrent les cas nominaux. Un cas tordu de la prod passera, d'où les règles de migration de [`operations/deployment.md`](../operations/deployment.md#migrations-et-donnees).

## Ce qui est coupé, et pourquoi

L'image embarque la vraie app et les vrais credentials. Tout ce qui sort vers l'extérieur est neutralisé dans `docker/local/compose.yml`. Les garde-fous marqués **(hors image)** ne dépendent pas du code de l'image : ils protègent aussi une image construite avant que l'interrupteur correspondant existe dans l'app (cas de `pull staging running` tant que le staging n'a pas été redéployé).

| Risque | Garde-fou |
| --- | --- |
| Envoi de mails réels (Mailjet) | **(hors image)** initializer monté dans le conteneur (`configs: local_guards`) : `perform_deliveries = false`, `delivery_method = :test`. En plus, `MAILER_DELIVERIES_ENABLED=false` pour les images récentes |
| Visites comptées dans Umami | **(hors image)** le proxy ajoute une seconde CSP `connect-src 'self' …` : le script Umami se charge mais ne peut envoyer aucun événement. En plus, `data-domains` sur les images récentes |
| Lecture de la réplique Litestream de production au démarrage | `LITESTREAM_RESTORE_ON_BOOT=false` (`bin/docker-entrypoint`), et **`bin/docker-local up production` refuse** une image dont l'entrypoint restaure Litestream sans cet interrupteur |
| Réplication Litestream vers le bucket de production | `LITESTREAM_REPLICATE_IN_PUMA` jamais défini |
| Sauvegarde nocturne rclone, rappels d'adhésion | `SOLID_QUEUE_SKIP_RECURRING=true` (les autres jobs tournent normalement) |
| HSTS de l'app appliqué à `localhost:3000` (`bin/dev`) | URLs en `127.0.0.1` : les navigateurs n'appliquent jamais HSTS à une IP |

Le proxy Caddy joue le rôle de `kamal-proxy` : HTTP simple, avec `X-Forwarded-Proto: https`, pour que `force_ssl` ne redirige pas. `bin/docker-local up` le recrée à chaque fois (Compose ne détecte pas les modifications de son Caddyfile inline).

Vérifier soi-même : `bin/docker-local console staging` puis `ActionMailer::Base.delivery_method` (doit répondre `:test`) ; `curl -sI -u staging:local http://127.0.0.1:8081/ | grep -i content-security` (deux lignes).

## Limites connues

**Image de production actuelle (avant réconciliation).** `circographe:latest` est encore construite depuis l'ancienne lignée `main` (octobre 2025, ancien modèle de données et seeds de démo) : sur une base neuve, son `db:prepare` échoue (`Could not find table 'solid_cache_entries'`) et le conteneur s'arrête. Ce n'est pas un défaut de l'outil : l'environnement `production` local deviendra utile quand `main` portera la lignée `dev`. D'ici là, utiliser `staging`.

**Credentials de production.** Quand `config/credentials/production.yml.enc` existera (réconciliation main ← dev, §5.0), l'image de production ne démarrera plus avec la master key commune : il lui faudra `production.key`, qu'on ne copie pas sur un poste de développement par défaut. On tranchera à ce moment-là (image staging uniquement, ou clé de prod sur un poste précis).
