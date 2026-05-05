# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "home_animations", to: "home_animations.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "global_animations", to: "global_animations.js"
pin "public_animations", to: "public_animations.js"
pin "turbo_page_reveal", to: "turbo_page_reveal.js"
pin "swiper" # @12.0.3
pin "swiper/bundle", to: "swiper--bundle.js" # @12.0.3
pin "confirm_modal", to: "confirm_modal.js"
pin "leaflet" # @1.9.4
# GSAP 3 — bundle ESM unique (Propshaft + imports relatifs multi-fichiers = 404 sans bundle).
# Régénérer : bundle exec rake gsap:bootstrap (npx esbuild)
pin "lib/gsap/register", to: "gsap-bootstrap.js", preload: false
pin "lib/gsap/animation_prefs", to: "lib/gsap/animation_prefs.js"
