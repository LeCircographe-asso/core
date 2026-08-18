import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "zip", "town", "results"]
  static values = {}

  connect() {
    this.timeout = null
    this.isSelecting = false
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.clearResults()
    }
  }

  async search(event) {
    if (this.isSelecting) {
      this.isSelecting = false
      return
    }

    const query = this.queryTarget.value.trim()

    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    if (query.length < 3) {
      this.clearResults()
      return
    }

    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const url = `https://api-adresse.data.gouv.fr/search/?q=${encodeURIComponent(query)}&limit=5&autocomplete=1`
      const response = await fetch(url)

      if (!response.ok) {
        this.clearResults()
        return
      }

      const data = await response.json()
      this.displayResults(data.features || [])
    } catch (error) {
      console.error("Address search error:", error)
      this.clearResults()
    }
  }

  displayResults(features) {
    if (features.length === 0) {
      this.resultsTarget.innerHTML = `<div class="px-3 py-2 text-sm text-gray-500">${this.t("no_results")}</div>`
      this.resultsTarget.style.display = "block"
      return
    }

    const html = features
      .map((feature, index) => {
        const { name, postcode, city } = feature.properties
        return `
          <button
            type="button"
            class="w-full text-left px-3 py-2 hover:bg-gray-100 transition-colors text-sm border-b border-gray-100 last:border-b-0"
            data-action="click->address-autocomplete#selectAddress"
            data-address-name="${this.escapeHtml(name)}"
            data-address-zip="${postcode || ''}"
            data-address-town="${this.escapeHtml(city || '')}"
          >
            <div class="font-medium text-gray-900">${this.escapeHtml(name)}</div>
            <div class="text-xs text-gray-500">${postcode || ''} ${city || ''}</div>
          </button>
        `
      })
      .join("")

    this.resultsTarget.innerHTML = html
    this.resultsTarget.style.display = "block"
  }

  selectAddress(event) {
    event.preventDefault()
    const button = event.currentTarget

    const address = button.dataset.addressName
    const zip = button.dataset.addressZip
    const town = button.dataset.addressTown

    this.queryTarget.value = address
    this.zipTarget.value = zip
    this.townTarget.value = town

    this.clearResults()

    // Set a short timeout to prevent search from running on the input event we're about to trigger
    this.isSelecting = true
    setTimeout(() => {
      this.isSelecting = false
    }, 50)

    // Trigger input/change events so other controllers know the value changed
    this.queryTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.queryTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.style.display = "none"
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  t(key) {
    // Simple fallback translation — could be enhanced with a proper i18n system
    const translations = {
      no_results: "Aucun résultat"
    }
    return translations[key] || key
  }
}
