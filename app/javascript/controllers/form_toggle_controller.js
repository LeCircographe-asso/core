import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-toggle"
export default class extends Controller {
  static targets = ["webAccountFields", "emailField", "newsletterNote"]

  connect() {
    this.refresh()
  }

  toggleWebAccountFields() {
    this.refresh()
  }

  toggleNewsletterNote() {
    this.refresh()
  }

  createWebAccountChanged() {
    this.refresh()
  }

  newsletterSubscribedChanged() {
    this.refresh()
  }

  refresh() {
    const webAccountChecked = this.webAccountCheckbox?.checked || false
    const newsletterChecked = this.newsletterCheckbox?.checked || false

    if (this.hasWebAccountFieldsTarget) {
      this.webAccountFieldsTarget.classList.toggle("hidden", !webAccountChecked)
    }

    if (this.hasNewsletterNoteTarget) {
      this.newsletterNoteTarget.classList.toggle("hidden", !newsletterChecked)
    }

    if (this.hasEmailFieldTarget) {
      this.emailFieldTarget.required = webAccountChecked || newsletterChecked
    }
  }

  get webAccountCheckbox() {
    return this.element.querySelector('input[name="user[create_web_account]"]')
  }

  get newsletterCheckbox() {
    return this.element.querySelector('input[name="user[person][newsletter_subscribed]"]')
  }
}
