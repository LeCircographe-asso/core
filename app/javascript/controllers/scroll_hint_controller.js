import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll-hint"
export default class extends Controller {
  static targets = ["arrow"]
  static values = { sectionId: String }

  connect() {
    if (!this.sectionIdValue) return

    const section = document.getElementById(this.sectionIdValue)
    if (!section) return

    this.observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.hide()
        } else {
          this.show()
        }
      })
    }, { threshold: 0.3 })

    this.observer.observe(section)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  hide() {
    if (!this.hasArrowTarget) return
    this.arrowTarget.classList.add("opacity-0", "pointer-events-none")
  }

  show() {
    if (!this.hasArrowTarget) return
    this.arrowTarget.classList.remove("opacity-0", "pointer-events-none")
  }
}
