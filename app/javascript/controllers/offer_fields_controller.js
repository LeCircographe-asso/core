import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["paymentMethod", "customAmount", "offerReason", "offerReasonInput"]

  connect() {
    this.refresh()
  }

  refresh() {
    const offered = this.paymentMethodTarget.value === "offered"

    if (this.hasCustomAmountTarget) {
      this.customAmountTarget.classList.toggle("hidden", !offered)
    }

    if (this.hasOfferReasonTarget) {
      this.offerReasonTarget.classList.toggle("hidden", !offered)
    }

    if (this.hasOfferReasonInputTarget) {
      this.offerReasonInputTarget.required = offered
    }
  }
}
