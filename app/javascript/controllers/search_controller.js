import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { 
    url: String,
    debounceMs: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
    this.inputTarget.addEventListener('input', this.handleInput.bind(this))
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  handleInput(event) {
    const query = event.target.value.trim()
    
    // Clear previous timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Debounce the search
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceMsValue)
  }

  performSearch(query) {
    if (query.length < 2) {
      this.clearResults()
      return
    }

    // Construire l'URL avec les paramètres existants
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('search', query)
    
    // Conserver les autres paramètres (filtres, page, etc.)
    const currentParams = new URLSearchParams(window.location.search)
    currentParams.forEach((value, key) => {
      if (key !== 'search' && key !== 'page') {
        url.searchParams.set(key, value)
      }
    })

    // Effectuer la recherche via Turbo
    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Mettre à jour la page avec les résultats
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Search error:', error)
    })
  }

  clearResults() {
    // Recharger la page sans paramètre de recherche
    const url = new URL(window.location)
    url.searchParams.delete('search')
    url.searchParams.delete('page')
    
    window.location.href = url.toString()
  }

  // Méthode pour vider le champ de recherche
  clear() {
    this.inputTarget.value = ''
    this.clearResults()
  }
}
