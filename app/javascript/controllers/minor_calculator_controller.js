import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="minor-calculator"
// Shows a contextual alert when the entered birth date indicates a minor.
// The actual is_minor flag and reduced rate are computed server-side (Person#before_save).
export default class extends Controller {
  static targets = ["birthDate", "statusDisplay"]

  connect() {
    this.updateDisplay()
  }

  updateDisplay() {
    if (!this.hasBirthDateTarget || !this.hasStatusDisplayTarget) return

    const value = this.birthDateTarget.value
    if (!value) {
      this.statusDisplayTarget.classList.add("hidden")
      return
    }

    const isMinor = this.calculateIsMinor(value)
    const el = this.statusDisplayTarget
    el.classList.remove("hidden")

    if (isMinor) {
      el.innerHTML = `
        <div class="rounded-md border border-amber-200 bg-amber-50 p-3 flex items-start gap-2">
          <svg class="mt-0.5 h-4 w-4 flex-shrink-0 text-amber-500" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
          </svg>
          <div>
            <p class="text-sm font-medium text-amber-800">Personne mineure</p>
            <p class="text-xs text-amber-700 mt-0.5">Un tarif réduit (Mineur) sera automatiquement appliqué à l'enregistrement.</p>
          </div>
        </div>`
    } else {
      el.innerHTML = `
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
          Majeur
        </span>`
    }
  }

  calculateIsMinor(dateString) {
    const birth = new Date(dateString)
    const today = new Date()
    let age = today.getFullYear() - birth.getFullYear()
    const m = today.getMonth() - birth.getMonth()
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--
    return age >= 0 && age < 18
  }
}
