import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["formula", "summaryName", "summaryPrice", "summaryConstraint", "summaryAlert", "totalPrice"]

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

    if (this.hasTotalPriceTarget) {
      this.totalPriceTarget.textContent = this.formatEuros(this.totalCents(selectedFormula))
    }
  }

  // Prix du payeur + prix de chaque bénéficiaire additionnel qui a déjà une
  // personne sélectionnée (une ligne sans bénéficiaire choisi n'est pas
  // envoyée au serveur, donc ne doit pas compter dans le total affiché).
  totalCents(selectedFormula) {
    const payerCents = Number(selectedFormula.dataset.formulaPriceCents || 0)

    const rows = Array.from(this.element.querySelectorAll('[data-beneficiary-list-target="row"]'))
    const beneficiariesCents = rows.reduce((sum, row) => {
      const personId = row.querySelector('[data-beneficiary-list-target="personIdField"]')?.value
      if (!personId) return sum

      const checkedFormula = row.querySelector('input[type="radio"]:checked')
      return sum + Number(checkedFormula?.dataset.formulaPriceCents || 0)
    }, 0)

    return payerCents + beneficiariesCents
  }

  formatEuros(cents) {
    return `${(cents / 100).toLocaleString("fr-FR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €`
  }
}
