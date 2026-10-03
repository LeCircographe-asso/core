import { Controller } from "@hotwired/stimulus"

// Empêche l'ouverture du flow Google tant que les CGU / politique de
// confidentialité n'ont pas été explicitement acceptées sur la page
// d'inscription (le bouton Google est un formulaire séparé du formulaire
// email/mot de passe, donc son propre consentement ne peut pas être porté
// par la case à cocher du premier formulaire).
export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.sync()
  }

  sync() {
    this.submitTarget.disabled = !this.checkboxTarget.checked
  }
}
