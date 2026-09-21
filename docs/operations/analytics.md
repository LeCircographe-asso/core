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
- Port `127.0.0.1:3001` : accès admin local uniquement (debug/setup), pas
  exposé publiquement par ce biais

Ce stack tourne **à côté** du déploiement Kamal de l'app, pas dedans :
Kamal ne gère que `circographe` et `circographe-staging` (voir
`config/deploy.yml` / `deploy.staging.yml`). Umami se déploie/maj
indépendamment avec `docker compose pull && docker compose up -d` depuis
`docker/analytics/`.

**Prod et staging tournent sur le même VPS Ionos → une seule instance
Umami pour les deux**, pas de duplication d'infra. Umami gère plusieurs
sites depuis une seule instance : un site "staging" pour tester, un site
"prod" créé seulement une fois validé.

## Réseau : brancher Umami sur kamal-proxy

Kamal occupe déjà les ports 80/443 du VPS via `kamal-proxy` (SSL auto
Let's Encrypt pour `lecircographe.fr` et `staging.lecircographe.fr`).
Umami rejoint le réseau Docker partagé de Kamal (`kamal`, créé
automatiquement par Kamal) plutôt que d'ouvrir un port ou un vhost à part —
c'est pour ça que le compose déclare `networks: kamal: external: true`.

Une fois `docker compose up -d` lancé, enregistrer la route directement
dans le conteneur `kamal-proxy` :

```bash
docker exec kamal-proxy kamal-proxy deploy analytics \
  --host analytics.lecircographe.fr \
  --target umami:3000 \
  --tls
```

⚠️ À vérifier sur le VPS avant d'exécuter (je n'ai pas d'accès SSH depuis
cette session, donc pas pu valider ces deux points directement) :
- le nom réel du conteneur proxy (`docker ps | grep proxy`) — normalement
  `kamal-proxy`, mais à confirmer
- le nom du réseau partagé (`docker network ls | grep kamal`) — si
  différent de `kamal`, l'ajuster dans `docker-compose.yml`

## Déploiement — tester en staging d'abord

```bash
cd docker/analytics
cp .env.example .env
# générer les secrets et les coller dans .env :
openssl rand -hex 32   # -> UMAMI_APP_SECRET
openssl rand -hex 24   # -> UMAMI_DB_PASSWORD
docker compose up -d
docker compose ps            # umami-db healthy, umami up
```

Puis :
1. Enregistrer la route `kamal-proxy` ci-dessus (DNS `analytics.lecircographe.fr`
   déjà pointé sur le VPS, sinon l'ajouter chez le registrar)
2. Ouvrir `https://analytics.lecircographe.fr`, créer le compte admin
3. Créer un site **"Le Circographe — staging"** pointant sur
   `staging.lecircographe.fr`, récupérer son `website_id`
4. Ajouter le tag JS uniquement en staging (voir plus bas), vérifier que
   les pageviews remontent dans le dashboard Umami
5. Une fois validé sur quelques jours de trafic staging → créer le site
   prod, ajouter le tag en conditionnel `Rails.env.production?`

## Intégration front

```erb
<%# app/views/layouts/public.html.erb %>
<% if Rails.env.staging? || Rails.env.production? %>
  <script defer src="https://analytics.lecircographe.fr/script.js"
          data-website-id="<%= Rails.application.credentials.dig(Rails.env.to_sym, :umami_website_id) %>"></script>
<% end %>
```

Aucune gem, aucun tracking côté serveur — script statique servi par Umami.
Deux `website_id` différents (staging / prod) dans `config/credentials.yml.enc`
sous leur clé d'environnement respective, pour ne pas mélanger le trafic
staging (souvent des tests internes) avec les vraies stats prod.

## À faire avant mise en prod

- [ ] Provisionner secrets (`.env`, non commité) sur le VPS
- [ ] Vérifier nom du conteneur/réseau `kamal-proxy` réels sur le VPS
- [ ] `docker compose up -d` + enregistrement route `kamal-proxy`
- [ ] Vérifier RAM/CPU dispo sur le VPS avec la stack actuelle (`docker stats`)
- [ ] Backup `pg_dump` cron séparé des backups SQLite existants (voir `docs/backup-restore.md`)
- [ ] Définir une politique de rétention des pageviews dans l'admin Umami
- [ ] **Test staging** : créer le site staging, valider le tracking avant tout site prod
- [ ] Créer le site prod dans Umami, ajouter le `website_id` en credentials
- [ ] Ajouter le tag JS conditionnel au layout public
