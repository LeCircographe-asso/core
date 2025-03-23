// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "flowbite"
import "leaflet"

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