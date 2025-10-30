import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleSubmit(event) {
    if (event.detail.success) {
      // Close any open modals
      const modal = document.querySelector('[data-controller*="payment-modal"]')
      if (modal) {
        modal.dispatchEvent(new CustomEvent("close"))
      }
    }
  }
}
