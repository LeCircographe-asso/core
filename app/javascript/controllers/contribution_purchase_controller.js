import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["formula", "summaryName", "summaryPrice", "summaryConstraint", "summaryAlert"]

  connect() {
    this.refresh()
  }

  refresh() {
    const selectedFormula = this.formulaTargets.find((input) => input.checked)
    if (!selectedFormula) return

    this.summaryNameTarget.textContent = selectedFormula.dataset.formulaName || ""
    this.summaryPriceTarget.textContent = selectedFormula.dataset.formulaPrice || ""
    this.summaryConstraintTarget.textContent = selectedFormula.dataset.formulaConstraint || ""

    if (this.hasSummaryAlertTarget) {
      const alert = selectedFormula.dataset.formulaAlert || ""
      this.summaryAlertTarget.textContent = alert
      this.summaryAlertTarget.classList.toggle("hidden", alert.length === 0)
    }
  }
}
