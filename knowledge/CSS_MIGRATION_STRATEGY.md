# 🎨 CSS Migration Strategy — Le Circographe
*Updated 2025-11-09*

---

## 🎯 Objectives
- Run a single, predictable pipeline (Tailwind via `tailwindcss-rails` + Propshaft).
- Provide reusable design tokens for all new Hotwire features (Turbo Frames/Streams, Stimulus controllers).
- Keep the associative visual tone while reducing custom CSS debt.

---

## 🧱 Current Architecture Snapshot
- **Entry point**: `app/assets/tailwind/application.css` (imported from layout).
- **Utilities & components**: Tailwind utilities + Flowbite widgets; legacy DartSass files progressively retired.
- **Hotwire integration**: public pages now rely on Turbo Frames (`events_upcoming`, `newsletter_signup`, `faq_entries`) and Stimulus controllers (`nav_active`, `slider`, `timeline`, `checklist`). All UI states must derive their styling from Tailwind classes or shared tokens.
- **Accessibility**: `dyslexic-font-enabled`, `fade-in`, `parallax-background` remain standard utilities.

---

## 🌈 Global Design Tokens
Declared in `app/assets/tailwind/application.css`:
- `--brand-primary` `#1F5C55` — primary CTA, borders, focus rings.
- `--brand-accent` `#5836A5` — hover/active states, editorial highlights.

Usage pattern:
```css
.btn-primary {
  @apply text-white bg-[color:var(--brand-primary)] border-[color:var(--brand-primary)];
}
.link-accent {
  @apply text-[color:var(--brand-accent)] hover:text-[color:var(--brand-primary)];
}
```
> Favor Tailwind arbitrary values for consistency (`bg-[color:var(--brand-primary)]`, etc.).

---

## 🚦 Migration Progress
- [x] Tailwind entrypoint adopted across layouts.
- [x] Legacy navbar/contact styles mapped to Tailwind classes.
- [x] Page refactors (Accueil, Le Lieu, Nos Activités, Adhérer, À propos, Contact, FAQ) follow the new token palette.
- [x] Core buttons/forms/hero/tabs extracted to `app/assets/tailwind/components/`.
- [x] Dashboard/timeline patterns migrés (`dashboard.css`, `timeline.css`) et supprimés de `app/assets/stylesheets/application.css`.
- [x] Animations, tooltips, Stripe signup extraits (`animations.css`, `tooltips.css`, `stripe.css`) ; fichier legacy nettoyé.
- [x] Event carousel layout + admin tables migrés (`events.css`, `admin_table.css`).
- [ ] Move remaining DartSass partials into Tailwind-compatible modules (homepage, carousel, tooltips, Stripe forms, global animations).
- [ ] Extract Swiper/Flowbite overrides into `app/assets/tailwind/components/*.css`.
- [ ] Document component recipes (cards, timelines, admin UI) inside `docs/`.

---

## 🧭 Next Focus
1. **Component library** — terminer la migration des styles restants (éventuels résidus Sass: flash admin, legacy navbar, actiontext).
2. **Page-level scopes** — ajouter un dossier `pages/` pour les styles admin spécifiques si nécessaire.
3. **Build hygiene** — vérifier que Tailwind purge bien `app/views`, `app/components`, `app/javascript`.
4. **QA** — capturer des screenshots après chaque étape et comparer avant/après.

---

## ✅ Working Principles
- Keep controllers slim (Rails 8) by pushing presentation logic into partials with Tailwind classes.
- Any new Stimulus controller must rely on existing tokens; avoid embedding hex colors or raw spacing.
- When a page needs a custom variant, favour Tailwind plugin utilities or component partials rather than inline styles.
- Update this document after each significant CSS refactor to maintain a single source of truth.

---

*Outcome target*: lighter CSS bundles, faster builds, and a consistent visual language aligned with the refreshed public pages.

