import { Controller } from "@hotwired/stimulus"

// Shows / hides a panel from a button (mobile menu, "Mon espace" dropdown) and keeps
// aria-expanded in sync. With close-outside, a click elsewhere or Escape closes it.
//   <div data-controller="disclosure" data-disclosure-close-outside-value="true">
//     <button data-disclosure-target="button" data-action="disclosure#toggle" aria-expanded="false">
//     <div data-disclosure-target="panel" class="hidden">…</div>
export default class extends Controller {
  static targets = ["button", "panel"]
  static values = { closeOutside: { type: Boolean, default: false } }

  connect () {
    this.onDocumentClick = (event) => { if (!this.element.contains(event.target)) this.close() }
    this.onKeydown = (event) => {
      if (event.key !== "Escape" || !this.open) return
      this.close()
      this.buttonTarget.focus()
    }
    if (this.closeOutsideValue) {
      document.addEventListener("click", this.onDocumentClick)
      document.addEventListener("keydown", this.onKeydown)
    }
  }

  disconnect () {
    document.removeEventListener("click", this.onDocumentClick)
    document.removeEventListener("keydown", this.onKeydown)
  }

  toggle () {
    this.#set(!this.open)
  }

  close () {
    if (this.open) this.#set(false)
  }

  get open () {
    return !this.panelTarget.classList.contains("hidden")
  }

  #set (open) {
    this.panelTarget.classList.toggle("hidden", !open)
    this.buttonTarget.setAttribute("aria-expanded", open)
  }
}
