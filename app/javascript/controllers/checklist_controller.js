import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checklist"
export default class extends Controller {
  static targets = ["item"]

  toggle(event) {
    const item = event.currentTarget
    const indicator = item.querySelector(".checklist-indicator")

    item.classList.toggle("bg-[#1F5C55]/10")
    item.classList.toggle("border-[#1F5C55]")
    item.classList.toggle("shadow-lg")

    if (indicator) {
      indicator.classList.toggle("bg-[#1F5C55]")
      indicator.classList.toggle("text-white")
      indicator.textContent = indicator.textContent.trim() === "" ? "✓" : ""
    }
  }
}
