import { Controller } from "@hotwired/stimulus"

// Reloads the page once the server-side idle timeout has elapsed, so member data
// does not stay on screen on a shared computer. The reload hits the expired
// session and lands on the sign-in form. Any Turbo request resets the timer,
// mirroring server-side activity tracking.
const MARGIN_SECONDS = 5

export default class extends Controller {
  static values = { seconds: Number }

  connect() {
    this.reset = this.reset.bind(this)
    document.addEventListener("turbo:before-fetch-request", this.reset)
    this.reset()
  }

  disconnect() {
    document.removeEventListener("turbo:before-fetch-request", this.reset)
    clearTimeout(this.timer)
  }

  reset() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => window.location.reload(), (this.secondsValue + MARGIN_SECONDS) * 1000)
  }
}
