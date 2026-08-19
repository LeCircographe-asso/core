import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statCard", "actionButton", "tableRow"]
  
  connect() {
    this.initializeAnimations()
    this.initializeKeyboardShortcuts()
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
        break
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
