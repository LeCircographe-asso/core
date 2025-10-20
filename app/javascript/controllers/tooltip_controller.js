import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { content: String }

  connect() {
    this.element.addEventListener('mouseenter', this.showTooltip.bind(this))
    this.element.addEventListener('mouseleave', this.hideTooltip.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('mouseenter', this.showTooltip.bind(this))
    this.element.removeEventListener('mouseleave', this.hideTooltip.bind(this))
    this.hideTooltip()
  }

  showTooltip(event) {
    const content = this.contentValue || this.element.getAttribute('title') || this.element.getAttribute('data-tooltip-content')
    
    if (!content) return

    // Supprimer l'attribut title pour éviter le tooltip natif
    this.element.removeAttribute('title')
    
    // Créer le tooltip
    this.tooltip = document.createElement('div')
    this.tooltip.className = 'absolute z-50 px-2 py-1 text-xs text-white bg-gray-900 rounded shadow-lg pointer-events-none'
    this.tooltip.textContent = content
    
    // Positionner le tooltip
    document.body.appendChild(this.tooltip)
    this.positionTooltip(event)
  }

  hideTooltip() {
    if (this.tooltip) {
      this.tooltip.remove()
      this.tooltip = null
    }
  }

  positionTooltip(event) {
    if (!this.tooltip) return

    const rect = this.element.getBoundingClientRect()
    const tooltipRect = this.tooltip.getBoundingClientRect()
    
    // Position par défaut : en haut de l'élément
    let top = rect.top - tooltipRect.height - 8
    let left = rect.left + (rect.width / 2) - (tooltipRect.width / 2)
    
    // Ajuster si le tooltip sort de l'écran
    if (top < 0) {
      top = rect.bottom + 8 // En dessous
    }
    
    if (left < 0) {
      left = 8
    } else if (left + tooltipRect.width > window.innerWidth) {
      left = window.innerWidth - tooltipRect.width - 8
    }
    
    this.tooltip.style.top = `${top + window.scrollY}px`
    this.tooltip.style.left = `${left}px`
  }
}
