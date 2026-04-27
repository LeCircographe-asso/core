# 🧭 Refonte UX / UI et dynamique JS — **Le Circographe**
*(Working document — updated 2025-11-09)*

> **Statut** : internal (working document)
> **Public cible** : équipe produit
> **Provenance** : ex-`docs/design/refonte.md`, déplacé dans `docs/internal/` car feuille de route en cours, non stabilisée.
> **Référence stable design** : [`../design/color_system.md`](../design/color_system.md).

---

## 🎯 Vision synthétique
- Parcours public consolidé : `Accueil → Le Lieu → Adhérer | Nos Activités → À propos → Contact`.
- Pages revisitées : storytelling homogène, CTA cohérents, mise en avant de l’autogestion.
- Hotwire généralisé : Turbo Frames pour événements, newsletter, FAQ et états navbar ; Turbo Streams pour feedbacks.
- Stimulus factorisé : contrôleurs `nav_active`, `slider`, `timeline`, `checklist`, `scroll_hint` et `modal` prêts à accompagner la nouvelle navigation.

---

## 🗺️ Pages et fonctionnalités clefs
- **Accueil** : hero immersif, `shared/event_card` injectée dans `turbo_frame_tag :events_upcoming`, horaires en cache, indicateur “scroll down”.
- **Le Lieu** : fusion Cirque/Arts graphiques, sections mutualisées (`shared/place_section`), galerie pilotée par `slider_controller`.
- **Nos Activités** : filtres dynamiques (`turbo_frame_tag :events_tab`), onglets Stimulus, newsletter en Turbo Stream et message flash Hotwire.
- **Adhérer** : timeline animée, checklist interactive inspirée des contrôleurs bénévoles, tarifs chargés via partials et caches.
- **À propos** : slider équipe/partenaires partagé, historique avec `timeline_controller`.
- **Contact** : `form_with` en Turbo Stream, FAQ réutilisée, carte + horaires synchronisés.
- **FAQ** : storytelling d’entrée, données partagées (`PagesController#*_faq_entries`), accordéons Flowbite contrôlés par Stimulus.

---

## ⚙️ Hotwire & Stimulus
- Turbo Drive actif avec transitions `fade-in` (hook `global_animations`).
- Frames dédiés : `events_upcoming`, `newsletter_signup`, `faq_entries`, `account_state`, `partners`.
- Streams pour flash publics, formulaires newsletter/contact, checklist adhésion.
- Hooks communs : initialisation sur `turbo:load`, nettoyage Swiper/Flowbite sur `turbo:before-cache`.
- Surveillance systématique de `log/development.log` pour détecter N+1 ; Bullet activable en développement.

---

## 🎨 Design system & tokens CSS
- Tailwind (`tailwindcss-rails`) + Flowbite restent la fondation UI.
- Variables globales dans `app/assets/tailwind/application.css` :
  - `--brand-primary` (`#1F5C55`) pour CTA principaux, focus et bordures.
  - `--brand-accent` (`#5836A5`) pour hover, badges et contenus éditoriaux.
  - Utilisation recommandée avec les classes arbitraires Tailwind : `bg-[color:var(--brand-primary)]`, `text-[color:var(--brand-accent)]`, `border-[color:var(--brand-primary)]`.
- Bibliothèque de composants CSS structurée dans `app/assets/tailwind/components/` (boutons, formulaires, hero, badges, layout, dashboard, timeline, admin sidebar, animations, tooltips, Stripe, events, admin table, flash, actiontext).
- Tokens utilitaires partagés : `fade-in`, `parallax-background`, `dyslexic-font-enabled`.
- Garder les vues DRY : privilégier les partials (`shared/*`) et limiter les styles inline ; centraliser les variantes dans Tailwind + variables.

---

## 🔜 Prochaines actions
- Mutualiser totalement Swiper dans `slider_controller` (instanciation/destroy).
- Finaliser les services Rails (`EventQuery`, `MembershipTypeQuery`) pour alimenter les frames sans gonfler les controllers.
- Ajouter tests request/feature couvrant les flux Turbo (filtres événements, newsletter, contact).
- Documenter Stimulus (`app/javascript/controllers`) avec exemples d’usage Hotwire.

---

## ✅ Résultats attendus
- Navigation fluide, sans rupture de contexte.
- Pages plus courtes (≤3 scrolls) et lisibles.
- Réutilisation maximale des composants existants.
- Base prête pour extensions CRM/CMS tout en conservant l’ADN associatif.

---

**Mantra :** des pages simples, vivantes et fidèles à l’esprit collectif du Circographe.

