# Circographe UI Color System

## 1. Brand Palette

| Role                    | Token                | Hex       | Usage                                                                 |
|-------------------------|----------------------|-----------|-----------------------------------------------------------------------|
| Text / Body             | `--color-text-main`  | `#0B1220` | Paragraphs, titles on light surfaces                                 |
| Text Muted              | `--color-text-muted` | `#1F2937` | Secondary text, labels                                               |
| Surface Light           | `--color-surface`    | `#F7FAFC` | Section backgrounds, layout wrappers                                 |
| Surface Card            | `--color-card`       | `#FFFFFF` | Cards, panels, hero content blocks                                   |
| Overlay Dark            | `--color-overlay`    | `rgba(12,31,43,0.75)` | Text legibility on imagery (hero overlays)            |
| Brand Primary           | `--color-primary`    | `#1F5C55` | Main CTA, navigation highlights, tags                                |
| Brand Primary Dark      | `--color-primary-dark` | `#174A44` | Hover/active state, text on light backgrounds                         |
| Brand Accent (Violet)   | `--color-accent`     | `#5836A5` | Secondary CTA, links, highlights                                     |
| Brand Accent Dark       | `--color-accent-dark`| `#4C2D8A` | Hover/focus state aligned with violet identity                       |
| Accent Gradient Light   | `--color-accent-light`| `#6D28D9` | Optional gradient stops, badges                                     |
| Support Orange          | `--color-support`    | `#FF9119` | Notifications, spotlight accents                                    |

All colors meet WCAG AA contrast (4.5:1) when used as recommended:  
`#1F5C55` & `#5836A5` on `#FFFFFF` ≥ 6.4:1.  
For dark overlays, pair with `#FFFFFF` text + drop shadow for readability.

## 2. Tailwind Tokens

Add the palette to `tailwind.config.js`:

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        'brand-primary': '#1F5C55',
        'brand-primary-dark': '#174A44',
        'brand-accent': '#5836A5',
        'brand-accent-dark': '#4C2D8A',
        'surface-light': '#F7FAFC',
        'surface-card': '#FFFFFF',
        'text-main': '#0B1220',
        'text-muted': '#1F2937'
      }
    }
  }
}
```

## 4. Typography

### Available Fonts

| Font Name          | Font-family reference              | Usage suggestions                                        |
|--------------------|-------------------------------------|----------------------------------------------------------|
| Circographe        | `font-circographe` utility          | Hero titles, major headings, brand statements            |
| Rough Typewriter   | `font-rough-typewriter` utility     | Editorial highlights, quotes, storytelling accents       |
| Roboto             | Tailwind `font-sans` / `font-roboto` utility | Default body text, forms, navigation copy        |

Notes:
- Fonts are preloaded in `app/assets/tailwind/application.css`.  
- Combine `font-circographe` with the hero utilities for a strong brand presence.  
- Use `font-rough-typewriter` with restraint to maintain legibility; pair with sufficient line-height and contrast.  
- Default to Roboto (via `font-sans`) for paragraphs and longer content blocks.

## 5. Utility Classes

Create reusable classes in `app/assets/tailwind/application.css` (Tailwind @layer components):

```css
@layer components {
  .hero-overlay {
    @apply absolute inset-0 bg-gradient-to-br from-[#0B1220]/80 via-[#4C2D8A]/55 to-transparent mix-blend-multiply;
  }

  .hero-panel {
    @apply bg-[#0B1220]/70 backdrop-blur rounded-[28px] shadow-2xl px-6 sm:px-10 py-8 text-white drop-shadow-[0_4px_16px_rgba(0,0,0,0.45)];
  }

  .hero-img-filter {
    @apply brightness-75 saturate-110;
  }

  .text-shadow-hero { text-shadow: 0 4px 16px rgba(0,0,0,0.6); }
  .bg-overlay-dark { background: linear-gradient(135deg, rgba(12,18,43,0.55), rgba(12,18,43,0.15)); }

  .btn-primary {
    @apply inline-flex items-center gap-2 rounded-full border-2 border-brand-primary bg-brand-primary text-white hover:bg-white hover:text-brand-primary transition;
  }

  .btn-secondary {
    @apply inline-flex items-center gap-2 rounded-full border-2 border-brand-accent bg-brand-accent text-white hover:bg-white hover:text-brand-accent transition;
  }

  .btn-tertiary {
    @apply inline-flex items-center gap-2 rounded-full border-2 border-brand-primary bg-brand-primary text-white hover:bg-white hover:text-brand-primary transition;
  }

  .badge-accent {
    @apply inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-brand-accent/10 text-brand-accent border border-brand-accent/20;
  }
}
```

> Les définitions complètes sont visibles dans `application.css`. Ne redéclare pas d’hex dans les vues : utilise ces classes.

## 6. Hero Pattern

To guarantee contrast on imagery across pages (`home`, `faq`, `about`, `news`):

```erb
<section class="relative overflow-hidden rounded-[32px] shadow-2xl">
  <div class="absolute inset-0 hero-overlay"></div>
  <%= image_tag "home2.webp", class: "absolute inset-0 w-full h-full object-cover hero-img-filter" %>

  <div class="relative px-6 py-20 hero-panel">
    ...
  </div>
</section>
```

Add optional image adjustments:

```css
@layer components {
  .hero-img-filter {
    @apply brightness-75 saturate-110;
  }
}
```

### Home Hero (Legacy)

L’accueil conserve un hero minimaliste (titre + bouton + flèche) sans overlay :

```erb
<section class="relative ...">
  <div class="flex flex-col items-center gap-8 ...">
    <h1 id="title" class="font-circographe ... text-shadow-hero">Le Circographe</h1>
    <%= link_to ... class: "px-6 ..." %>
  </div>
</section>
```

- Pas d’utilisation de `.hero-overlay`/`.hero-panel` sur cette page pour garder le rendu historique.
- On peut utiliser `.text-shadow-hero` pour assurer la lisibilité du titre sur les images sombres.

Use `.hero-overlay` + `.hero-panel` pour FAQ/About et futures pages publiques qui ont besoin d’un panneau lisible sur fond photo.

## 7. Form Controls

| Usage | Classes | Notes |
|-------|---------|-------|
| Champ standard | `form-control` (optionnel) + `focus-accent` | Halo violet `#5836A5` 1px, fond blanc, bords arrondis. |
| Champ accentué | `focus-accent-strong` | Halo violet plus prononcé (anneau 2px). |

> Les projets antérieurs utilisaient `focus:border-[#1F5C55]` / `focus:ring-[#1F5C55]`. Un override dans `application.css` force désormais ces classes à pointer sur `#5836A5`. Pas besoin de réécrire le legacy, mais privilégie `focus-accent` pour les nouveaux écrans.

Exemple :

```erb
<%= form.email_field :email_address,
      class: "form-control focus-accent",
      placeholder: "ex. jean@example.com" %>
```

## 8. Implementation Playbook

1. **Add Tailwind tokens and utility classes** (see sections 2, 5, 7).  
2. **Update components**:
   - Replace inline `bg-[#1F5C55]`/`hover:text` by `.btn-primary` or `.btn-secondary`.
   - Use `badge-accent` for tags currently en vert.
   - Switch hero wrappers (`home`, `faq`, `about`, `news`) to `hero-overlay` + `hero-panel`.
3. **Refine partials**:
   - `shared/_navbar`, `shared/footer`, CTA partials → swap hex to tokens.
   - Introduce violet as secondary CTA (newsletter, call-to-action context).
4. **Audit forms** (`sessions/new`, `registrations/new`) to use accent violet for focus rings.
5. **Run Lighthouse / axe** to verify contrast on critical pages.
6. **Document** usage in README or DESIGN docs (link to this file).

## 9. Branch Strategy

1. Créer une branche dédiée (ex. `feature/ui-color-harmonization`).  
2. Appliquer les étapes ci-dessus progressivement (commit par step).  
3. Tester en local :
   - `bin/dev` + vérifier pages `home`, `faq`, `about`, `news`, formulaires.  
   - `bin/rails test` pour s’assurer qu’aucune régression JavaScript.  
4. Ouvrir une PR pour revue, intégrer feedback, merger une fois validé.

## 10. Bonnes Pratiques

- Toujours utiliser les classes Tailwind custom au lieu de hardcoder les hex.  
- Pour textes sur image : `.hero-panel` + `.hero-overlay`, sauf pour l’accueil qui reste minimal.  
- Boutons/violets : `.btn-secondary` pour mettre en avant l’identité tout en respectant le contraste.  
- Respecter `text-white` + `text-shadow-hero` si besoin sur backgrounds sombres.  
- Garder `#FF9119` uniquement pour notifications/accents, pas pour CTA principaux.  

## 11. Contrast Checklist

1. **Automatique** : `bin/rails tailwindcss:build` échoue si une classe inconnue est ajoutée. 
2. **Audit manuel** : utiliser Lighthouse ou `npx @axe-core/cli http://127.0.0.1:3001/` pour vérifier les ratios.
3. **Hex Watchdog** : `rg --no-heading "#[0-9a-fA-F]{6}" app/views` doit rester vide (sauf fichiers de config). Ajoute ce check dans les PR.
4. **Visuel** : vérifier à la main que textes blancs/brand sur images restent lisibles (utiliser `.text-shadow-hero` si nécessaire).

Cette base garantit un style cohérent, accessible et facilement maintenable sur l’ensemble du site. Ajuster au besoin via Tailwind, sans réintroduire d’hex isolés.


