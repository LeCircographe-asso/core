import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "membershipTypeSelect", "suggestedNumber", "customNumber"]

  connect() {
    this.originalValue = this.customNumberTarget.value
  }

  showChangeForm() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  hideChangeForm() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = "auto"
    this.resetForm()
  }

  updateSuggestedNumber() {
    const membershipType = this.membershipTypeSelectTarget.value
    this.generateSuggestedNumber(membershipType)
  }

  generateNewNumber() {
    const membershipType = this.membershipTypeSelectTarget.value
    this.generateSuggestedNumber(membershipType)
  }

  generateSuggestedNumber(membershipType) {
    // Faire une requête AJAX pour générer un nouveau numéro
    fetch('/admin/member_numbers/suggest', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: JSON.stringify({
        membership_type: membershipType
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.suggestedNumberTarget.value = data.suggested_number
        this.customNumberTarget.value = data.suggested_number
      } else {
        this.showError(data.error || 'Erreur lors de la génération du numéro')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showError('Erreur de connexion')
    })
  }

  resetForm() {
    this.formTarget.reset()
    this.customNumberTarget.value = this.originalValue
  }

  showError(message) {
    // Créer une notification d'erreur temporaire
    const errorDiv = document.createElement('div')
    errorDiv.className = 'fixed top-4 right-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded z-50'
    errorDiv.textContent = message
    
    document.body.appendChild(errorDiv)
    
    setTimeout(() => {
      errorDiv.remove()
    }, 5000)
  }

  // Gérer la fermeture avec Escape
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.hideChangeForm()
    }
  }
}
