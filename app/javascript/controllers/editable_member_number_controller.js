import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "editButton"]
  static values = { personId: String }

  connect() {
    this.originalValue = this.inputTarget.value
  }

  edit() {
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.cancel()
    } else if (event.key === "Enter") {
      event.preventDefault()
      this.save()
    }
  }

  save() {
    const newValue = this.inputTarget.value.trim()
    
    if (newValue === this.originalValue) {
      return
    }

    // Show loading state
    this.inputTarget.disabled = true
    this.inputTarget.classList.add("opacity-50")

    // Submit form with AJAX
    fetch(this.formTarget.action, {
      method: 'PATCH',
      body: new FormData(this.formTarget),
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.success()
        // Show success message (optional)
        this.showMessage(data.message, 'success')
      } else {
        this.error()
        this.showMessage(data.errors.join(', '), 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.error()
      this.showMessage('Erreur de connexion', 'error')
    })
  }

  cancel() {
    this.inputTarget.value = this.originalValue
    this.inputTarget.blur()
  }

  // Called after successful form submission
  success() {
    this.originalValue = this.inputTarget.value
    this.inputTarget.disabled = false
    this.inputTarget.classList.remove("opacity-50")
  }

  // Called after failed form submission
  error() {
    this.inputTarget.value = this.originalValue
    this.inputTarget.disabled = false
    this.inputTarget.classList.remove("opacity-50")
  }

  showMessage(message, type) {
    // Create a temporary message element
    const messageEl = document.createElement('div')
    messageEl.className = `fixed top-4 right-4 px-4 py-2 rounded-lg text-sm font-medium z-50 ${
      type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
    }`
    messageEl.textContent = message
    
    document.body.appendChild(messageEl)
    
    // Remove after 3 seconds
    setTimeout(() => {
      messageEl.remove()
    }, 3000)
  }
}
