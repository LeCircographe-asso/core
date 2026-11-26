import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checklist"
export default class extends Controller {
  static targets = ["item"]

  toggle(event) {
    const item = event.currentTarget
    const indicator = item.querySelector(".checklist-indicator")

    item.classList.toggle("bg-brand-primary/10")
    item.classList.toggle("border-brand-primary")
    item.classList.toggle("shadow-lg")

    if (indicator) {
      indicator.classList.toggle("bg-brand-primary")
      indicator.classList.toggle("text-white")
      indicator.textContent = indicator.textContent.trim() === "" ? "✓" : ""
    }
  }
}
