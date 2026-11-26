# Mailjet & envoi d'emails

> **Statut (2026-10-03)** : dev = Letter Opener Web · staging = Mailjet (compte perso, `sandbox`) · production = branchée sur Mailjet (compte Circographe) mais **éteinte**.

## Principe

| Env | Livraison | Clés | Mails réellement envoyés ? |
| --- | --- | --- | --- |
| development | `:letter_opener_web` ([development.rb](../../config/environments/development.rb)) | aucune | **Non** — consultation sur `http://localhost:3000/letter_opener` |
| test | `:test` | aucune | Non |
| staging | SMTP `in-v3.mailjet.com:587` ([staging.rb](../../config/environments/staging.rb)) | `credentials.yml.enc` → `mailjet.sandbox` (compte **perso**) | **Seulement à l'équipe** : filtre `StagingMailGuard` (voir ci-dessous) |
| production | SMTP `in-v3.mailjet.com:587` ([production.rb](../../config/environments/production.rb)) | `config/credentials/production.yml.enc` → `mailjet.production` (compte **Circographe**) | **Non tant que `MAILER_DELIVERIES_ENABLED` ≠ `true`** |

Jamais de clé de production hors de la production : staging ne doit pas pouvoir déchiffrer `mailjet.production` (voir [plan de réconciliation §5.0](../migrations/main_reconciliation_plan.md)).

## Staging : testable, sans jamais écrire à un adhérent

Le staging contient des données de test et contiendra bientôt de vrais adhérents (import CSV). Le filtre [`StagingMailGuard`](../../app/mailers/staging_mail_guard.rb), branché uniquement dans `staging.rb`, passe sur **chaque** mail, rappels d'expiration compris :

| Destinataire | Ce qui se passe |
| --- | --- |
| dans `MAIL_ALLOWLIST` (adresses ou `@domaine`, séparés par des virgules) | reçu normalement |
| tout autre (To, Cc, Bcc) | retiré ; si `MAIL_REDIRECT_TO` est défini, le mail y part, sujet préfixé `[staging → destinataire d'origine]` et en-tête `X-Staging-Original-Recipients` ; sinon il n'est pas envoyé |
| rien de configuré | **aucun mail ne part** |

Réglage : variables GitHub (*Settings → Secrets and variables → Actions → Variables*) `STAGING_MAIL_ALLOWLIST` et `STAGING_MAIL_REDIRECT_TO`, prises en compte au prochain déploiement staging. Ce sont des adresses, pas des secrets ; elles ne sont jamais écrites dans le dépôt.

Vérifier un flux : chaque mail laisse une ligne `[StagingMailGuard] delivered|redirected|suppressed` (adresses masquées) dans les logs, `pro-applogs staging grep StagingMailGuard 1d`. Déclencher les rappels sans attendre 8 h : `bin/kamal app exec --reuse "bin/rails runner MembershipExpirationReminderJob.perform_now" -c config/deploy.staging.yml` (adhésions actives qui expirent dans exactement 30 jours).

## Production : « branché mais éteint »

`production.rb` fixe `perform_deliveries` à `ENV["MAILER_DELIVERIES_ENABLED"] == "true"` (défaut : faux). Le flag est posé à `false` dans `config/deploy.production.yml`. Éteint, les mails sont construits et journalisés mais jamais transmis à Mailjet : aucune erreur, aucun envoi. `spec/config/mailer_delivery_spec.rb` verrouille ce comportement.

**Allumer** (uniquement après validation du parcours en staging) :
1. Clés `mailjet.production.api_key` / `secret_key` présentes dans `production.yml.enc`.
2. `MAILER_DELIVERIES_ENABLED: true` dans `config/deploy.production.yml`, PR, promotion, redeploy.
3. Envoyer **un seul** mail de test (mot de passe oublié) à une adresse de l'équipe, vérifier SPF/DKIM dans les en-têtes.

## Domaine et adresses

- Domaine `lecircographe.fr` validé chez Mailjet via le lien IONOS : SPF unique (`include:spf.mailjet.com` + `include:_spf-eu.ionos…`), DKIM `mailjet._domainkey`, DKIM IONOS, DMARC géré par IONOS (CNAME). Un seul SPF dans la zone, à ne jamais dupliquer.
- Les mails automatiques partent de `no-reply@lecircographe.fr` (aucune boîte nécessaire : l'envoi est autorisé par la validation du domaine).
- `contact@lecircographe.fr` : boîte IONOS Email Basic avec redirection vers le Gmail de l'association ; Gmail « Envoyer en tant que » via `smtp.ionos.fr:587` pour répondre depuis cette adresse.
- Staging (compte perso) ne peut pas envoyer depuis `@lecircographe.fr` (domaine non validé sur ce compte) : l'expéditeur doit y être une adresse validée sur le compte perso, via `MAILER_FROM`.

## Mailers

`UserMailer` (bienvenue, bienvenue par admin, rappel d'expiration, confirmation d'événement, contact), `PasswordsMailer` (reset, changed), `AccountClaimMailer`, `DonationMailer` (reçu).

## Checklist avant d'allumer la production

- [ ] Parcours validé en staging : mot de passe, bienvenue, rattachement de compte, reçu de don, contact, rappels
- [ ] Liens des mails corrects par environnement (pas d'URL de prod en dur)
- [ ] Liens de désinscription newsletter fonctionnels (RGPD)
- [ ] `mailjet.production` renseigné, `RAILS_MASTER_KEY` de production isolée de staging
- [ ] Mail de test reçu hors spam, SPF/DKIM `pass`
- [ ] Gestion des rebonds (bounces) décidée
