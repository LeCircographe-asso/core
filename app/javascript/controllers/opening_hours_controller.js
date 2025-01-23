import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hoursSection", "timeInput", "openRadio", "closedRadio"]

  toggleStatus(event) {
    const isClosed = event.target.value === "closed"
    const inputs = this.timeInputTargets
    
    inputs.forEach(input => {
      input.disabled = isClosed
    })

    this.hoursSectionTarget.style.opacity = isClosed ? "0.5" : "1"
  }

  connect() {
    // Initialiser l'état au chargement
    if (this.hasClosedRadioTarget && this.closedRadioTarget.checked) {
      this.timeInputTargets.forEach(input => {
        input.disabled = true
      })
      this.hoursSectionTarget.style.opacity = "0.5"
    }
  }
} 