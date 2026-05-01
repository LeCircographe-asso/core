# TODO — Le Circographe (Rails 8 / MVC)
> **Statut** : interne  
> **Public cible** : équipe dev  
> **Dernière mise à jour** : 2026-06-02  
> **Provenance** : centralisation des anciens fichiers (`to-do.md` racine et `docs/TODO.md`).

> ⚠️ **Note d'identité (2026-05)** — Tout `User` possède une `Person`. (`users.person_id` NOT NULL en DB, création minimale à l’inscription, aucune donnée « orpheline »). Cf. [README](../../README.md) + [naming-rules.mdc](../../.cursor/rules/naming-rules.mdc)
>
> ⚠️ **Note de vocabulaire (2026-05-01 — migration terminée)** — Les anciens noms `SubscriptionCreator`, `SubscriptionUpgrader`, `SubscriptionPlan`, `BookOfEntry` ont disparu.  
> Vocabulaire : `Contribution`, `ContributionFormula`, `People::ContributionCreator`, `People::ContributionUpgrader`.  
> **Exception** : on conserve `subscription` uniquement pour la newsletter. Cf. [`../glossary.md`](../glossary.md).

---

> Ordonnancement : du rapide/peu risqué au long terme.  
> Chaque point est pensé pour pouvoir être découpé en micro-PR.

----

## 0b) Plan de clarification progressive (PR itératives, simple → métier)
- [x] **PR 1 — Audit de similarité :** Cartographie des vrais doublons entre `models/services/controllers/helpers/components` ; classement fusion/garde/report.
  - DoD : mini-tableau de décision/fusion, liste des micro-PR.
  - **Fait (2026-05-01)** :
    - Garder : `People::ContributionCreator` ≠ `ContributionUpgrader`.
    - Fusionner/Alléger : controller admin user / branches user/person, prioriser helpers/présenters.
    - Reporter dette : cohabitation `subscription_*` / `contribution_*`.
    - Attention : `Admin::SubscriptionPlansController` (nom legacy, opère sur `ContributionFormula`).

- [x] **PR 2 — Validation usages :** Vérification contrats d’entrée/sortie, effets de bord, couverture tests avant fusion.
  - DoD : pas de fusion sans preuve d’équivalence métier.
  - **Fait (2026-05-01)** :
    - Orchestration par `People::Register` ; check controller admin/users (liaison manual).  
    - Callbacks cachés `Payment`/`PaymentLine` : effet à rendre explicite moyen terme.

- [x] **PR 3 — Alignement vocabulaire (safe)** : partout Person/Membership/Contribution/Payment.
  - DoD : review listing et naming, mapping stable PR par PR.
  - Fait : services Contribution majoritaires ; legacy admin: routes/controllers à migrer explicite, mapping stable en doc.

- [x] **PR 4 — Règle e-mail (médium)** : centraliser la règle Person.email <-> User.email_address (cas exceptés/bloqués, messages).
  - DoD : collisions cross-table bloquées/explicites/auditables.

- [x] **PR 5 — Visibilité callback (médium)** : au moins 1 callback métier rendu explicite côté service/flow.
  - DoD : aucun changement de comportement, log métier lisible accru.

- [x] **PR 6 — Extraction ciblée (médium+)** : micro-policy depuis Person (API inchangée, rollback facile).
  - DoD : tests verts, diff court.

#### 0b.1) Scopes rapides/simple (pas de refonte)
- [x] **Scope A — Lisibilité du flow Admin::UsersController** : extractions helpers privés ``show/destroy``, suppression branchements trop longs.
- [x] **Scope B — Bordure vocabulaire** : docs à jour sur legacy restant, pourquoi.
  - 2026-05-01 : admin routes/params migrées vers `contribution_formula_*`, legacy = controllers + labels restants.
  - 2026-05-01 : nouveau contrôleur canonique, ancien utilisé comme shim temporaire.
  - Retrait : docs, vues, renommages et suppression shim, vérif runtime.
  - **2026-05-01 (final)** : toutes étapes hold/travail legacy migrées/retirées (voir historique docs/I18n/vues).

- [x] **Scope C — Cohérence e-mail identité** : centralisation via `Identity::EmailPolicy`, validations et specs (cf. cross-table `Person`/`User`).
- [x] **Scope D — Inventaire des callbacks** :
  - 2026-05-01 :
    - Payment : UUID (tech), audit log, update status/cache.
    - Attendance : set_date default, after_create business consumption.
    - User : ensure_person, after_create token, welcome explicite via service.

---

## 0) *Ground Rules* (Arch + MVC)
- Documentation complète du cycle de vie Person/User : [`docs/domain/happy_path_flows.md`].
- Person = source d’identité + finance.
- Controller maigre : service, render/redirect uniquement.
- Logic métier = modèles/services, pas controllers.
- Offres : always reason + audit.

---

## 1) Court terme (quick win, peu risqué)
- **Audit UI publique 2026-05-01** – Fait. Cf. [`ux_audit_2025_01.md`](ux_audit_2025_01.md#audit-contenu-ui-public--résolu-2026-05-01)
- Marquer les vues `*_old.html.erb` en `LEGACY` avant suppression – Fait.
- Onglets utilisateurs admin : Stimulus tabs – Fait.
- Partials partagés paiements + contenu tabs – Fait.
- Fix pack10 (copy, date d’exp. supprimée) – Fait.
- Forcer `offer_reason` UI si payment_method = offered – Fait (adhésion+contribution).
- Permettre don optionnel (ligne don) lors d’achat adhésion/contribution – Fait.
- “Sessions remaining” masqué sur plans illimités – Partiel (user views + cartes).
- Total admin paiement/dons = somme lignes don – Fait.
- Mettre à jour cette to-do/docks continuellement – En cours.
- **Feature flags produit + rôles :**  
  1. Un schéma unique pour activer/désactiver fonctionnalités (inscription publique, reset password, etc.) **en plus** des rôles ;
  2. Lecture centralisée (helper/FeatureFlags);
  3. Garde-fou serveur/UI;
  4. Prochaines étapes : extensibilité et dashboard admin de flag.

---

## 2) Moyen terme (cohérence/intégrité flows)
- [x] Registration admin = `People::Register` only (aussi update)
- [x] Link compte = service only, no `user.person = …` direct dans controlleur
- [x] Création membership par service only
- [x] Achat contribution par service only
- [x] Upgrades via leurs services only
- [x] `Person` possible sans `User`
- [x] Signup web : User ⇒ Person always (callback + DB)
- [x] Empêcher relink implicite sur `Person` déjà liée
- [x] Don n’impacte pas adhésion (ligne séparée).
- À faire : afficher raison “offer_reason” partout (histo paiement/adhésion/contrib).
- Afficher détails don ligne dans historique paiements.
- Vérifier/enforcer offer_reason admin paiement offert aussi.
- Vérif/intégrité plans illimits: sessions_remaining = nil.
- Vérif : somme payment_lines == paiement total.
- Action admin explicite link User↔Person (UI/perm à tester)
- Migration Stimulus pour scripts inline restants
- Uniformisation styles/espacement admin (paiement/adhésion/contribution)
- Cleanup components legacy

---

## 3) Docs (alignement, cohérence)
- [x] Doc “Happy flows” (inscription, link, achat, don, etc.) – 2026-05-01
- [x] Checklist “Data integrity rules” – 2026-05-01
- [x] “Role permissions” – 2026-05-01
- [x] README central comme index – 2026-05-01
- [x] Vérification régulière testing.md + architecture/controllers.md – legacy purgés 2026-05-01

---

## 4) Tests (moyen > long)
- [x] Request spec health/user archive
- [x] Fix bug SQLite admin user creation
- Request spec offerte (offer_reason)
- Request spec ligne don paiement
- Integrity unlimited plans
- Spec: somme payment lines = total paiement
- Orphelins
- Service specs Register/Attach/AccountLinker/Creator
- Controller specs admin succès/échec
- ViewComponent specs
- System spec onglets admin

---

## 5) Paiement : intégrité et accountability (long)
- Retirer tout usage user_id dans payments (reste Admin::PaymentsController#322)
- recorded_by obligatoire
- Lignes don legacy fix/migration: aucun don en type "Payment"
- Annulation (=void/cancel) à la place suppression
- Métadonnées reçu don (numéro, date, par qui)
- PDF/reçu mail service don
- Action admin issue/resent reçus
- Filtres reporting don

---

## 6) RGPD (long)
- Remplacer hard delete → anonymisation
- Refus suppression Person avec paiement/adhésion
- Audit anonymisation (raison/acteur)
- Helpers soft-delete, incluant User réactivation (scope with_deleted)
- Soft-delete User admin (archive!)

---

## 7) Jobs cohérence données (long)
- Rake : détecter/réparer payment_lines manquantes
- Backfill lignes don legacy
- Rapport contributions illimitées/cohérence sessions

---

## 7b) Nettoyage code suite audit doc (2026-04-27)
- [x] Orphelins `EventManagement::*` supprimés, CRUD events inline. (Cf. audit doc 2026-04-27)

---

## 8) Rollout (ordre)
1. Health report (fait)
2. Paiement/user_link fixé (fait)
3. Enregistrement/liaison via service only (audit en cours)
4. Suppression → anonymisation
5. Nettoyage vues legacy
6. Ajout/extension tests
