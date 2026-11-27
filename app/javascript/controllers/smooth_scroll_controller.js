import { Controller } from "@hotwired/stimulus"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

// In-page link (href="#id") that scrolls smoothly to its target instead of jumping, without a
// Turbo visit or the page reveal animation. Respects reduced motion.
//   <a href="#horaires" data-controller="smooth-scroll" data-action="smooth-scroll#go">
export default class extends Controller {
  go (event) {
    const id = this.element.getAttribute("href")?.replace(/^#/, "")
    const target = id && document.getElementById(id)
    if (!target) return
    event.preventDefault()

    const top = this.#layoutTop(target) - 16
    window.scrollTo({ top, behavior: prefersReducedMotion() ? "auto" : "smooth" })
    history.replaceState(history.state, "", `#${id}`)
  }

  // Position in the page layout, ignoring transforms: sections with a reveal animation
  // (.fade-in, translated until shown) would otherwise make the scroll overshoot.
  #layoutTop (element) {
    let top = 0
    for (let el = element; el; el = el.offsetParent) top += el.offsetTop
    return top
  }
}
