import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-feedback"
export default class extends Controller {
  static targets = ["message"]

  connect() {
    this.submitButton = this.element.querySelector('[type="submit"]')
    this.startListener = this.handleStart.bind(this)
    this.endListener = this.handleEnd.bind(this)

    this.element.addEventListener("turbo:submit-start", this.startListener)
    this.element.addEventListener("turbo:submit-end", this.endListener)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.startListener)
    this.element.removeEventListener("turbo:submit-end", this.endListener)
  }

  handleStart() {
    if (!this.submitButton) return
    this.originalText = this.submitButton.innerHTML
    this.submitButton.disabled = true
    this.submitButton.classList.add("opacity-70", "cursor-not-allowed")
    this.submitButton.innerHTML = "Envoi…"
  }

  handleEnd(event) {
    if (this.submitButton) {
      this.submitButton.disabled = false
      this.submitButton.classList.remove("opacity-70", "cursor-not-allowed")
      this.submitButton.innerHTML = this.originalText || this.submitButton.innerHTML
    }

    if (this.hasMessageTarget) {
      const { success } = event.detail
      this.messageTarget.textContent = success ? "Merci, nous revenons vers toi rapidement !" : "Une erreur est survenue. Vérifie le formulaire puis réessaie."
      this.messageTarget.classList.remove("hidden")
    }
  }
}
