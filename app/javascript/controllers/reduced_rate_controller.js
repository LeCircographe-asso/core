import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reduced-rate"
export default class extends Controller {
  static targets = ["details", "checkbox", "select", "reason", "proof"]

  connect() {
    this.refresh()
  }

  refresh() {
    this.toggleDetails()
    this.toggleProof()
  }

  // Deux déclencheurs possibles : une case à cocher (fiche personne) ou un
  // <select> de type d'adhésion dont l'option choisie porte data-reduced-rate="true"
  // (formulaire d'adhésion — cf. Admin::MembershipsHelper#membership_type_select_options).
  isReducedRateActive() {
    if (this.hasSelectTarget) {
      const option = this.selectTarget.selectedOptions[0]
      return option ? option.dataset.reducedRate === "true" : false
    }

    const checkbox = this.checkboxTarget || this.element.querySelector('input[type="checkbox"]')
    return checkbox ? checkbox.checked : false
  }

  toggleDetails() {
    if (!this.hasDetailsTarget) return

    if (this.isReducedRateActive()) {
      this.detailsTarget.classList.remove('hidden')
    } else {
      // Only hide if no value is present
      const select = this.detailsTarget.querySelector('select')
      if (!select || select.value === '') {
        this.detailsTarget.classList.add('hidden')
      }
    }
  }

  // Action when the checkbox changes
  checkboxChanged() {
    this.refresh()
  }

  // Action when the membership type select changes
  selectChanged() {
    this.refresh()
  }

  reasonChanged() {
    this.toggleProof()
  }

  toggleProof() {
    if (!this.hasProofTarget || !this.hasReasonTarget) return

    const shouldShowProof = this.reasonTarget.value === "Autre"
    this.proofTarget.classList.toggle("hidden", !shouldShowProof)
  }
}
