# Assets Lock (Rails 8.1 + Propshaft)

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

8) Troubleshooting
- If styles vanish: ensure `bin/dev` is running; check app/assets/builds/tailwind.css.
- If admin content offset is wrong: ensure .admin-content toggles `expanded` and .admin-main padding rules are intact.
