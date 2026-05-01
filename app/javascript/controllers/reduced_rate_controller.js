import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reduced-rate"
export default class extends Controller {
  static targets = ["details", "checkbox", "reason", "proof"]

  connect() {
    this.refresh()
  }

  refresh() {
    this.toggleDetails()
    this.toggleProof()
  }

  toggleDetails() {
    const checkbox = this.checkboxTarget || this.element.querySelector('input[type="checkbox"]')
    
    if (this.hasDetailsTarget && checkbox) {
      if (checkbox.checked) {
        this.detailsTarget.classList.remove('hidden')
      } else {
        // Only hide if no value is present
        const select = this.detailsTarget.querySelector('select')
        if (!select || select.value === '') {
          this.detailsTarget.classList.add('hidden')
        }
      }
    }
  }

  // Action when checkbox changes
  checkboxChanged() {
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
