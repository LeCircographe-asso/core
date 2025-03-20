import { Controller } from "@hotwired/stimulus"

// Contrôleur Stimulus pour gérer les accordéons
export default class extends Controller {
  connect() {
    // Initialiser Flowbite si disponible
    if (typeof initFlowbite === 'function') {
      initFlowbite();
    }
    
    // Initialiser manuellement tous les accordéons
    this.initAccordions();
  }
  
  initAccordions() {
    // Récupérer tous les boutons d'accordéon du conteneur
    const accordionButtons = this.element.querySelectorAll('[data-accordion-target]');
    
    accordionButtons.forEach(button => {
      button.addEventListener('click', this.toggleAccordion);
    });
  }
  
  toggleAccordion(event) {
    const button = event.currentTarget;
    const targetId = button.getAttribute('data-accordion-target');
    const targetElement = document.querySelector(targetId);
    
    if (targetElement) {
      const isHidden = targetElement.classList.contains('hidden');
      if (isHidden) {
        targetElement.classList.remove('hidden');
        button.setAttribute('aria-expanded', 'true');
        // Rotation de l'icône
        const icon = button.querySelector('[data-accordion-icon]');
        if (icon) icon.classList.remove('rotate-180');
      } else {
        targetElement.classList.add('hidden');
        button.setAttribute('aria-expanded', 'false');
        // Rotation de l'icône
        const icon = button.querySelector('[data-accordion-icon]');
        if (icon) icon.classList.add('rotate-180');
      }
    }
  }
} 