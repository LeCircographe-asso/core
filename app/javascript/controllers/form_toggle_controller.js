import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-toggle"
export default class extends Controller {
  static targets = ["webAccountFields", "emailField", "newsletterNote"]

  connect() {
    console.log('Form toggle controller connected!')
    this.toggleWebAccountFields()
    this.toggleNewsletterNote()
  }

  toggleWebAccountFields() {
    console.log('toggleWebAccountFields called')
    const checkbox = this.element.querySelector('input[name="user[create_web_account]"]')
    console.log('Checkbox found:', checkbox)
    console.log('Checkbox checked:', checkbox?.checked)
    
    if (this.hasWebAccountFieldsTarget && checkbox) {
      if (checkbox.checked) {
        this.webAccountFieldsTarget.style.display = 'block'
        console.log('Showing web account fields')
        if (this.hasEmailFieldTarget) {
          this.emailFieldTarget.required = true
        }
      } else {
        this.webAccountFieldsTarget.style.display = 'none'
        console.log('Hiding web account fields')
        if (this.hasEmailFieldTarget) {
          this.emailFieldTarget.required = false
        }
      }
    }
  }

  toggleNewsletterNote() {
    const checkbox = this.element.querySelector('input[name="user[person][newsletter_subscribed]"]')
    if (this.hasNewsletterNoteTarget && checkbox) {
      if (checkbox.checked) {
        this.newsletterNoteTarget.style.display = 'block'
        if (this.hasEmailFieldTarget) {
          this.emailFieldTarget.required = true
        }
      } else {
        this.newsletterNoteTarget.style.display = 'none'
        if (this.hasEmailFieldTarget) {
          this.emailFieldTarget.required = false
        }
      }
    }
  }

  // Actions
  createWebAccountChanged() {
    console.log('createWebAccountChanged called')
    this.toggleWebAccountFields()
  }

  newsletterSubscribedChanged() {
    console.log('newsletterSubscribedChanged called')
    this.toggleNewsletterNote()
  }
}
