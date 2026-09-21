# Analytics — Umami (recherche / branche en attente)

> **Statut** : en recherche, non déployé | **Branche** : `claude/loving-brahmagupta-tyrq63`

## Contexte

Besoin de mesurer le trafic du site public (pages vues, referrers, sources)
sans dépendre de Google Analytics (RGPD : cookies tiers, bandeau de
consentement, transfert de données hors UE — incohérent avec une asso qui
héberge tout elle-même en self-hosted).

Umami a été choisi plutôt que GoatCounter (SQLite natif, mais UI plus
austère) et plutôt que Plausible (nécessite Postgres + ClickHouse, plus
lourd). Umami reste raisonnable en ressources (~300-400 Mo RAM avec sa DB)
pour un VPS Ionos qui fait déjà tourner l'app Rails.

Umami est **totalement indépendant** de l'app : sa Postgres n'a aucun lien
avec le SQLite de Rails, pas de gem ajoutée, pas de code Ruby de tracking.
Le seul point de contact est un tag `<script>` dans le layout public.

Le backoffice (authentifié) n'est pas couvert par Umami — si besoin de
tracer l'usage des membres connectés, voir la piste Ahoy (gem Rails,
DB SQLite séparée) discutée en parallèle.

## Stack

Fichiers : `docker/analytics/docker-compose.yml` + `docker/analytics/.env.example`

- `umami-db` : Postgres 16, dédiée à Umami, volume nommé `umami_db_data`
- `umami` : image officielle `postgresql-latest`, migrations auto au démarrage
- Port exposé uniquement en local (`127.0.0.1:3001`) — accès public via reverse-proxy

Ce stack tourne **à côté** du déploiement Kamal de l'app, pas dedans :
Kamal ne gère que `circographe` (voir `config/deploy.yml`). Umami se
déploie/maj indépendamment avec `docker compose pull && docker compose up -d`
depuis `docker/analytics/`.

## Déploiement (à faire, pas encore exécuté)

```bash
cd docker/analytics
cp .env.example .env
# générer les secrets :
openssl rand -hex 32   # -> UMAMI_APP_SECRET
openssl rand -hex 24   # -> UMAMI_DB_PASSWORD
docker compose up -d
```

Reverse-proxy (le proxy Kamal gère déjà `lecircographe.fr` — ajouter un
vhost séparé pour le sous-domaine analytics, ex. via Caddy/Traefik/Nginx
existant sur le VPS) :

```
analytics.lecircographe.fr -> 127.0.0.1:3001
```

## Intégration front

```erb
<%# app/views/layouts/public.html.erb %>
<script defer src="https://analytics.lecircographe.fr/script.js"
        data-website-id="<%= Rails.application.credentials.umami_website_id %>"></script>
```

Aucune gem, aucun tracking côté serveur — script statique servi par Umami.
Ajouter `umami_website_id` dans `config/credentials.yml.enc` une fois le
site créé dans l'admin Umami.

## À faire avant mise en prod

- [ ] Provisionner secrets (`.env`, non commité)
- [ ] Vérifier RAM/CPU dispo sur le VPS avec la stack actuelle (`docker stats`)
- [ ] Backup `pg_dump` cron séparé des backups SQLite existants (voir `docs/backup-restore.md`)
- [ ] Définir une politique de rétention des pageviews dans l'admin Umami
- [ ] Créer le site dans Umami et récupérer le `website_id`
- [ ] Ajouter le tag JS au layout public + credential
