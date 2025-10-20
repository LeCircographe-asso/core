import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statCard", "actionButton", "tableRow"]
  
  connect() {
    console.log("Admin Users Controller connected")
    this.initializeTooltips()
    this.initializeAnimations()
  }
  
  // Initialiser les tooltips
  initializeTooltips() {
    const tooltipElements = document.querySelectorAll('[data-controller="tooltip"]')
    tooltipElements.forEach(element => {
      element.addEventListener('mouseenter', this.showTooltip.bind(this))
      element.addEventListener('mouseleave', this.hideTooltip.bind(this))
    })
  }
  
  // Afficher un tooltip
  showTooltip(event) {
    const element = event.target
    const content = element.getAttribute('data-tooltip-content') || element.getAttribute('title')
    
    if (!content) return
    
    // Créer le tooltip
    const tooltip = document.createElement('div')
    tooltip.className = 'tooltip absolute z-50 px-2 py-1 text-sm text-white bg-gray-900 rounded shadow-lg'
    tooltip.textContent = content
    tooltip.style.top = `${element.offsetTop - 35}px`
    tooltip.style.left = `${element.offsetLeft}px`
    
    // Ajouter au DOM
    element.style.position = 'relative'
    element.appendChild(tooltip)
    
    // Animation
    setTimeout(() => tooltip.classList.add('show'), 10)
  }
  
  // Masquer un tooltip
  hideTooltip(event) {
    const element = event.target
    const tooltip = element.querySelector('.tooltip')
    if (tooltip) {
      tooltip.remove()
    }
  }
  
  // Initialiser les animations
  initializeAnimations() {
    // Animation des cartes de statistiques
    this.statCardTargets.forEach((card, index) => {
      card.style.animationDelay = `${index * 0.1}s`
      card.classList.add('animate-fade-in')
    })
    
    // Animation des lignes du tableau
    this.tableRowTargets.forEach((row, index) => {
      row.style.animationDelay = `${index * 0.05}s`
      row.classList.add('animate-slide-in')
    })
  }
  
  // Gestion des clics sur les cartes de statistiques
  statCardClick(event) {
    const card = event.currentTarget
    const statType = card.dataset.statType
    
    // Ajouter un effet de clic
    card.style.transform = 'scale(0.95)'
    setTimeout(() => {
      card.style.transform = ''
    }, 150)
    
    // Filtrer selon le type de statistique
    if (statType) {
      this.filterByStatType(statType)
    }
  }
  
  // Filtrer par type de statistique
  filterByStatType(statType) {
    const filterSelect = document.querySelector('select[name="filter"]')
    if (filterSelect) {
      filterSelect.value = statType
      filterSelect.form.submit()
    }
  }
  
  // Gestion des actions rapides
  quickAction(event) {
    const action = event.currentTarget.dataset.action
    const personId = event.currentTarget.dataset.personId
    
    // Ajouter un effet visuel
    event.currentTarget.style.transform = 'scale(1.1)'
    setTimeout(() => {
      event.currentTarget.style.transform = ''
    }, 200)
    
    // Exécuter l'action
    switch(action) {
      case 'view':
        window.location.href = `/admin/users/person_${personId}`
        break
      case 'create_account':
        window.location.href = `/admin/users/new?person_id=${personId}`
        break
      case 'add_membership':
        window.location.href = `/admin/memberships/new?person_id=${personId}`
        break
      default:
        console.log(`Action ${action} not implemented`)
    }
  }
  
  // Recherche en temps réel
  searchInput(event) {
    const query = event.target.value
    const searchController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="search"]'), 
      'search'
    )
    
    if (searchController) {
      // Délai pour éviter trop de requêtes
      clearTimeout(this.searchTimeout)
      this.searchTimeout = setTimeout(() => {
        searchController.performSearch(query)
      }, 300)
    }
  }
  
  // Exporter les données
  exportData(event) {
    const format = event.currentTarget.dataset.format || 'csv'
    const filters = this.getCurrentFilters()
    
    // Afficher un indicateur de chargement
    const button = event.currentTarget
    const originalText = button.textContent
    button.textContent = 'Export en cours...'
    button.disabled = true
    
    // Construire l'URL d'export
    const params = new URLSearchParams(filters)
    params.set('format', format)
    
    // Rediriger vers l'export
    window.location.href = `/admin/exports/all_users?${params.toString()}`
    
    // Restaurer le bouton après un délai
    setTimeout(() => {
      button.textContent = originalText
      button.disabled = false
    }, 2000)
  }
  
  // Obtenir les filtres actuels
  getCurrentFilters() {
    const form = document.querySelector('form[action*="admin/users"]')
    if (!form) return {}
    
    const formData = new FormData(form)
    const filters = {}
    
    for (let [key, value] of formData.entries()) {
      if (value) filters[key] = value
    }
    
    return filters
  }
  
  // Gestion des raccourcis clavier
  handleKeyboard(event) {
    // Ctrl/Cmd + K pour focus sur la recherche
    if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
      event.preventDefault()
      const searchInput = document.querySelector('input[name="search"]')
      if (searchInput) {
        searchInput.focus()
        searchInput.select()
      }
    }
    
    // Échap pour effacer la recherche
    if (event.key === 'Escape') {
      const searchInput = document.querySelector('input[name="search"]')
      if (searchInput && searchInput.value) {
        searchInput.value = ''
        searchInput.form.submit()
      }
    }
  }
  
  // Initialiser les raccourcis clavier
  initializeKeyboardShortcuts() {
    document.addEventListener('keydown', this.handleKeyboard.bind(this))
  }
  
  disconnect() {
    // Nettoyer les event listeners
    document.removeEventListener('keydown', this.handleKeyboard.bind(this))
  }
}
