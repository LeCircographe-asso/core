import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nav-active"
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.handleTurboLoad = this.markActive.bind(this)
    document.addEventListener("turbo:load", this.handleTurboLoad)
    this.markActive()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.handleTurboLoad)
  }

  markActive() {
    const path = window.location.pathname
    const hash = window.location.hash.replace(/^#/, "")

    this.linkTargets.forEach(link => {
      const targetPath = link.dataset.navActivePath || link.pathname
      const anchor = link.dataset.navActiveAnchor
      const startsWith = link.dataset.navActiveStartsWith === "true"

      let active = false

      if (anchor) {
        active = path === targetPath && hash === anchor
      } else if (startsWith) {
        active = path === targetPath || path.startsWith(`${targetPath}/`)
      } else {
        active = path === targetPath
      }

      this.toggleClasses(link, active)
    })
  }

  toggleClasses(link, add) {
    const classes = (link.dataset.navActiveActiveClasses || "").split(/\s+/).filter(Boolean)
    classes.forEach(cls => {
      if (add) {
        link.classList.add(cls)
      } else {
        link.classList.remove(cls)
      }
    })
  }
}
