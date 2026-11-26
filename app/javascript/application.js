// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "lib/gsap/register"
import "controllers"
import "home_animations"
import "global_animations"
import "public_animations"
import "turbo_page_reveal"
import "confirm_modal"
import "whatsapp_qr_modal"

import "trix"
import "@rails/actiontext"

// Register once on first load (idempotent but no need to re-run on Turbo navigations)
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker
      .register("/service-worker", { scope: "/" })
      .catch((error) => console.warn("Service worker registration failed:", error))
  })
}
