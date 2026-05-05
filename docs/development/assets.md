# Assets Lock (Rails 8.1 + Propshaft)

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-04-27
> **Sources de vérité** : `Gemfile`, `app/assets/`, `bin/dev`, `bin/rails assets:doctor`.

Keep these rules to avoid breaking the asset pipeline.

1) Tailwind
- Entry: app/assets/tailwind/application.css with `@tailwind base/components/utilities`.
- Served via: `<%= stylesheet_link_tag "tailwind" %>` (build to app/assets/builds/tailwind.css).
- Run with `bin/dev` (uses Tailwind watcher).

2) Flowbite (local)
- Files: vendor/js/flowbite.css, vendor/js/flowbite.turbo.min.js.
- Layout order: Tailwind → Flowbite → Application.
- Includes:
  - `<%= stylesheet_link_tag "flowbite" %>`
  - `<%= javascript_include_tag "flowbite.turbo.min", "data-turbo-track": "reload" %>`

3) Fonts
- Place fonts in app/assets/fonts/ (woff2/woff/otf).
- Reference in CSS with absolute URLs /fonts/... (Propshaft rewrites to fingerprinted /assets/...).

4) No SCSS/Sass
- Project does not use SCSS. `dartsass-rails` removed.
- Do not add application.scss or browser @import.

5) Admin layout offset
- Sidebar is fixed. Offset lives on .admin-main only:
  - `padding-left: calc(25px + 260px)`; collapsed: `calc(25px + 70px)`.
- Do not use margins/width calcs; it breaks alignment.

6) Doctor
- Run `bin/rails assets:doctor` before commits/releases.
- Fails if Tailwind/Flowbite/fonts or layout tags are missing.

7) CDN policy
- No CDN for Flowbite. External CDNs allowed: Stripe, Font Awesome, Swiper.
- **GSAP 3** : servi en local via `config/importmap.rb` + répertoire `vendor/javascript/gsap` (paquet npm complet, **pas** de fichiers aplatis JSPM uniques — les imports relatifs du package le requièrent). Point d’entrée applicatif : `app/javascript/lib/gsap/register.js` (`gsap.registerPlugin` unique, `turbo:before-cache` pour `context` / ScrollTrigger / ScrollSmoother). **Pas de CDN GSAP.**
- Préférence d’accessibilité partagée : `app/javascript/lib/gsap/animation_prefs.js` (`prefersReducedMotion`), aligné sur `home_animations.js`.
- **Migration progressive** : ne pas remplacer d’un coup `home_animations.js` / `global_animations.js` ; utiliser `gsapScoped` / `trackGsapContext` pour les nouveaux blocs ou les Stimulus ciblés lorsque le bootstrap est utilisé.

8) Troubleshooting
- If styles vanish: ensure `bin/dev` is running; check app/assets/builds/tailwind.css.
- If admin content offset is wrong: ensure .admin-content toggles `expanded` and .admin-main padding rules are intact.
