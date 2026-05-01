import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  open() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove("hidden")
      document.body.style.overflow = "hidden"
    }
  }

  close() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.add("hidden")
      document.body.style.overflow = ""
      // Clear the form
      const form = this.containerTarget.querySelector("form")
      if (form) form.reset()
    }
  }

  handleSubmit(event) {
    if (event.detail.success) {
      this.close()
      // Reload the page to show new payment and update totals
      window.location.reload()
    } else {
      // Show errors
      console.error("Payment creation failed:", event.detail)
      // Keep modal open to show errors
    }
  }
}
