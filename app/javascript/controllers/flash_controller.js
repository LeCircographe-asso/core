import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notification"]

  connect() {
    // Auto-hide après 8 secondes (plus long que l'ancien système)
    this.timeoutId = setTimeout(() => {
      this.close()
    }, 8000)
  }

  disconnect() {
    // Nettoyer le timeout si le composant est détruit
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  close() {
    // Ajouter la classe de fermeture pour l'animation
    this.element.classList.add('flash-closing')
    
    // Supprimer l'élément après l'animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
