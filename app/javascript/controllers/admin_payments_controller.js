import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Raccourci clavier Ctrl+K pour focus sur la recherche
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
    
    // Auto-submit du formulaire de recherche avec debounce
    const searchInput = this.element.querySelector('#search')
    if (searchInput) {
      this.searchTimeout = null
      this.boundSearchInput = this.handleSearchInput.bind(this)
      searchInput.addEventListener('input', this.boundSearchInput)
    }
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeydown)
    const searchInput = this.element.querySelector('#search')
    if (searchInput && this.boundSearchInput) {
      searchInput.removeEventListener('input', this.boundSearchInput)
    }
  }

  handleKeydown(event) {
    if (event.ctrlKey && event.key === 'k') {
      event.preventDefault()
      const searchInput = this.element.querySelector('#search')
      if (searchInput) {
        searchInput.focus()
      }
    }
  }

  handleSearchInput(event) {
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      if (event.target.value.length >= 2 || event.target.value.length === 0) {
        event.target.form.submit()
      }
    }, 500)
  }

  clearSearch() {
    const searchInput = this.element.querySelector('#search')
    if (searchInput) {
      searchInput.value = ''
      const form = this.element.querySelector('form')
      if (form) {
        form.submit()
      }
    }
  }

  changeItemsPerPage(event) {
    const items = event.target.value
    const url = new URL(window.location)
    url.searchParams.set('items', items)
    url.searchParams.delete('page') // Reset to first page
    window.location.href = url.toString()
  }
}

