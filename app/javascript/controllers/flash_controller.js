import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progress"]

  static values = {
    duration: { type: Number, default: 8000 },
    exitDuration: { type: Number, default: 350 },
  }

  connect() {
    this.element.style.setProperty("--flash-duration", `${this.durationValue}ms`)
    this.element.style.setProperty("--flash-exit-duration", `${this.exitDurationValue}ms`)

    this.timeoutId = window.setTimeout(() => this.close(), this.durationValue)
  }

  disconnect() {
    if (this.timeoutId) window.clearTimeout(this.timeoutId)
  }

  close() {
    if (this.timeoutId) {
      window.clearTimeout(this.timeoutId)
      this.timeoutId = null
    }

    if (this.hasProgressTarget) {
      this.progressTarget.classList.add("flash-progress-paused")
    }

    this.element.classList.add("flash-closing")

    window.setTimeout(() => {
      this.element.remove()
    }, this.exitDurationValue)
  }
}
