import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "itemsPerPage"]
  static values = { debounceMs: { type: Number, default: 500 } }

  connect() {
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleGlobalKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleGlobalKeydown)
    if (this.searchTimeout) clearTimeout(this.searchTimeout)
  }

  debouncedSearch(event) {
    if (this.searchTimeout) clearTimeout(this.searchTimeout)

    this.searchTimeout = setTimeout(() => {
      const valueLength = event.target.value.length
      if (valueLength >= 2 || valueLength === 0) {
        event.target.form.requestSubmit()
      }
    }, this.debounceMsValue)
  }

  clearSearch(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.searchTimeout) clearTimeout(this.searchTimeout)

    const url = new URL(window.location.href)
    url.searchParams.delete("search")
    url.searchParams.delete("page")
    window.location.href = url.toString()
  }

  changeItemsPerPage(event) {
    const items = event.target.value
    const url = new URL(window.location.href)
    url.searchParams.set("items", items)
    url.searchParams.delete("page")
    window.location.href = url.toString()
  }

  handleGlobalKeydown(event) {
    if ((event.ctrlKey || event.metaKey) && event.key === "k") {
      event.preventDefault()
      if (this.hasSearchInputTarget) this.searchInputTarget.focus()
    }
  }
}
