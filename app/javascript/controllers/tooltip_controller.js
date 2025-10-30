import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }
  
  connect() {
    console.log("Tooltip controller connected")
    this.setupTooltip()
  }
  
  setupTooltip() {
    // Supprimer l'ancien tooltip s'il existe
    this.removeTooltip()
    
    // Ajouter les event listeners
    this.element.addEventListener('mouseenter', this.showTooltip.bind(this))
    this.element.addEventListener('mouseleave', this.hideTooltip.bind(this))
  }
  
  showTooltip(event) {
    if (!this.contentValue) return
    
    // Créer le tooltip
    this.tooltip = document.createElement('div')
    this.tooltip.className = 'tooltip-tooltip absolute z-50 px-3 py-2 text-sm text-white bg-gray-900 rounded-lg shadow-lg pointer-events-none'
    this.tooltip.textContent = this.contentValue
    
    // Positionner le tooltip
    const rect = this.element.getBoundingClientRect()
    this.tooltip.style.position = 'fixed'
    this.tooltip.style.top = `${rect.top - 40}px`
    this.tooltip.style.left = `${rect.left + (rect.width / 2)}px`
    this.tooltip.style.transform = 'translateX(-50%)'
    
    // Ajouter au body
    document.body.appendChild(this.tooltip)
    
    // Animation
    this.tooltip.style.opacity = '0'
    this.tooltip.style.transition = 'opacity 0.2s ease-in-out'
    setTimeout(() => this.tooltip.style.opacity = '1', 10)
  }
  
  hideTooltip(event) {
    this.removeTooltip()
  }
  
  removeTooltip() {
    if (this.tooltip) {
      this.tooltip.style.opacity = '0'
      setTimeout(() => {
        if (this.tooltip && this.tooltip.parentNode) {
          this.tooltip.parentNode.removeChild(this.tooltip)
        }
        this.tooltip = null
      }, 200)
    }
  }
  
  disconnect() {
    this.removeTooltip()
    this.element.removeEventListener('mouseenter', this.showTooltip)
    this.element.removeEventListener('mouseleave', this.hideTooltip)
  }
}