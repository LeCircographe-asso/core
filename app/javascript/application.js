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

// Définir la fonction initFlowbite si elle n'existe pas déjà
if (typeof window.initFlowbite !== 'function') {
  window.initFlowbite = function() {
    // Chercher la fonction initFlowbite dans l'objet global flowbite
    if (typeof flowbite !== 'undefined' && typeof flowbite.initAccordions === 'function') {
      flowbite.initAccordions();
      flowbite.initCollapses();
      flowbite.initDialogs();
      flowbite.initDrawers();
      flowbite.initDropdowns();
      flowbite.initModals();
      flowbite.initPopovers();
      flowbite.initTabs();
      flowbite.initTooltips();
    }
  };
}

document.addEventListener("turbo:load", () => {
    window.initFlowbite();
});
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
