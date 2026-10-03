# Analytics — Umami

> **Statut** : déployé sur le VPS, tag front branché, en attente de credential `website_id` staging
> **Branche** : `feature/umami-analytics`

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

Bonus découvert dans les migrations Umami au premier démarrage : heatmap
et session replay existent nativement dans l'édition récente (tables
`add_heatmap` / `add_session_replay`). À explorer plus tard pour la
"zone chaude" une fois le trafic de base validé — pas besoin de PostHog.

## Stack

Fichiers : `docker/analytics/docker-compose.yml` + `docker/analytics/.env.example`

- `umami-db` : Postgres 16, dédiée à Umami, volume nommé `umami_db_data`
- `umami` : image officielle `postgresql-latest`, migrations auto au démarrage
- Port `127.0.0.1:3001` : accès admin local uniquement (debug/setup), pas
  exposé publiquement par ce biais

Ce stack tourne **à côté** du déploiement Kamal de l'app, pas dedans :
Kamal ne gère que `circographe` et `circographe-staging` (voir
`config/deploy.yml` / `deploy.staging.yml`). Sur le VPS, pas de plugin
`docker compose` (v2) installé — seulement le binaire legacy
`docker-compose` (v1.29.2). Syntaxe avec tiret, flags avant le nom du
service (`docker-compose logs --tail=50 umami`, pas l'inverse).

**Prod et staging tournent sur le même VPS Ionos (82.165.63.129) → une
seule instance Umami pour les deux**, pas de duplication d'infra. Umami
gère plusieurs sites depuis une seule instance : un site "staging" pour
tester, un site "prod" créé seulement une fois validé.

## Réseau : Umami branché sur kamal-proxy

Kamal occupe déjà les ports 80/443 du VPS via `kamal-proxy` (SSL auto
Let's Encrypt pour `lecircographe.fr` et `staging.lecircographe.fr`).
Umami rejoint le réseau Docker partagé de Kamal (réseau `kamal`, confirmé
présent sur le VPS) plutôt que d'ouvrir un port ou un vhost à part — c'est
pour ça que le compose déclare `networks: kamal: external: true`.

Route enregistrée dans `kamal-proxy` :

```bash
docker exec kamal-proxy kamal-proxy deploy analytics \
  --host analytics.lecircographe.fr \
  --target umami:3000 \
  --health-check-path / \
  --tls
```

Le `--health-check-path /` est nécessaire : le défaut de `kamal-proxy`
(`/up`, convention Rails) n'existe pas côté Umami (Next.js) et fait
échouer le déploiement de la route avec `target failed to become healthy`.

Vérifié en prod sur le VPS (03/10/2026) :
```
Service    Host                         Path  Target       State    TLS
analytics  analytics.lecircographe.fr   /     umami:3000   running  yes
```
`curl -I https://analytics.lecircographe.fr` → `200 OK`, certificat Let's
Encrypt délivré automatiquement.

## Déploiement effectué

```bash
cd docker/analytics
cp .env.example .env
# générer les secrets et les coller dans .env (attention aux lignes vides
# du template qui dupliquent les clés — repartir d'un .env propre si besoin) :
openssl rand -hex 32   # -> UMAMI_APP_SECRET
openssl rand -hex 24   # -> UMAMI_DB_PASSWORD
docker-compose up -d
docker-compose ps            # umami-db healthy, umami up
```

Login initial Umami : `admin` / `umami` — **à changer immédiatement**
(Settings → Profile) après la première connexion.

## Intégration front (faite)

Helper `umami_website_id` dans `app/controllers/application_controller.rb` :
nil hors staging/production, ou si le credential n'est pas encore défini
pour l'environnement courant — le tag ne s'affiche simplement pas tant
que ce n'est pas configuré, pas besoin de feature flag séparé.

```ruby
def umami_website_id
  return nil unless Rails.env.staging? || Rails.env.production?

  Rails.application.credentials.dig(:umami, Rails.env.to_sym, :website_id)
end
```

Tag dans `app/views/layouts/application.html.erb` (`<head>`), exclu du
backoffice (`controller_path.start_with?("admin/")`) :

```erb
<% if umami_website_id && !controller_path.start_with?("admin/") %>
<script defer src="https://analytics.lecircographe.fr/script.js" data-website-id="<%= umami_website_id %>"></script>
<% end %>
```

CSP (`config/initializers/content_security_policy.rb`) mise à jour :
`analytics.lecircographe.fr` ajouté à `script-src` (chargement du script)
et `connect-src` (beacon d'envoi des events) — sans ça le navigateur
bloque silencieusement le tracking.

Credentials à ajouter (`bin/rails credentials:edit`) :
```yaml
umami:
  staging:
    website_id: <uuid du site staging créé dans l'admin Umami>
  production:
    website_id: <uuid du site prod, à créer après validation staging>
```

## Reste à faire

- [x] Déployer le stack sur le VPS (prod + staging partagés)
- [x] Brancher la route `kamal-proxy` avec SSL
- [x] Code front (helper + tag layout + CSP)
- [ ] Changer le mot de passe admin Umami par défaut
- [ ] Créer le site **staging** dans l'admin Umami, récupérer le `website_id`
- [ ] Ajouter `umami.staging.website_id` aux credentials, déployer sur staging
- [ ] Valider quelques jours de trafic staging dans le dashboard Umami
- [ ] Créer le site **prod**, ajouter `umami.production.website_id`
- [ ] Backup `pg_dump` cron séparé des backups SQLite existants (voir `docs/backup-restore.md`)
- [ ] Définir une politique de rétention des pageviews dans l'admin Umami
