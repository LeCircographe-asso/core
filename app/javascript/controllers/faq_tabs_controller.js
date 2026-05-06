import { Controller } from "@hotwired/stimulus"
import { gsap } from "lib/gsap/register"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect () {
    this.panelTargets.forEach((panel, i) => {
      if (i > 0) {
        panel.hidden = true
        panel.style.opacity = "0"
      }
    })
    if (this.hasTabTarget) this.#activate(this.tabTargets[0])
  }

  show (event) {
    const tab = event.currentTarget
    const panelId = tab.dataset.faqTabsPanel
    const newPanel = this.panelTargets.find(p => p.id === panelId)
    const currentPanel = this.panelTargets.find(p => !p.hidden)

    if (!newPanel || newPanel === currentPanel) return

    this.tabTargets.forEach(t => this.#deactivate(t))
    this.#activate(tab)

    const instant = prefersReducedMotion()

    const reveal = () => {
      newPanel.hidden = false
      if (instant) {
        newPanel.style.opacity = "1"
      } else {
        gsap.fromTo(newPanel,
          { opacity: 0, y: 18 },
          { opacity: 1, y: 0, duration: 0.38, ease: "power3.out" }
        )
      }
    }

    if (currentPanel) {
      if (instant) {
        currentPanel.hidden = true
        reveal()
      } else {
        gsap.to(currentPanel, {
          opacity: 0, y: -12, duration: 0.22, ease: "power2.in",
          onComplete: () => { currentPanel.hidden = true; reveal() }
        })
      }
    } else {
      reveal()
    }
  }

  #activate (tab) {
    tab.setAttribute("aria-selected", "true")
    tab.dataset.active = "true"
  }

  #deactivate (tab) {
    tab.setAttribute("aria-selected", "false")
    delete tab.dataset.active
  }
}
