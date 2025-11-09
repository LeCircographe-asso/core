import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timeline"
export default class extends Controller {
  static targets = ["step"]

  connect() {
    if (!"IntersectionObserver" in window) return

    this.observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("timeline-step--visible")
          this.observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.3 })

    this.stepTargets.forEach(step => this.observer.observe(step))
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}
