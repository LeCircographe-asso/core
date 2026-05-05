import { Controller } from "@hotwired/stimulus"
import { gsap } from "lib/gsap/register"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

// Connects to data-controller="scroll-hint"
export default class extends Controller {
  static targets = ["arrow"]
  static values  = { sectionId: String }

  connect () {
    if (this.sectionIdValue) {
      const section = document.getElementById(this.sectionIdValue)
      if (section) {
        this.observer = new IntersectionObserver(entries => {
          entries.forEach(entry => entry.isIntersecting ? this.hide() : this.show())
        }, { threshold: 0.3 })
        this.observer.observe(section)
      }
    }

    this._arrowEl = this.element.querySelector(".scroll-arrow")
    if (this._arrowEl) {
      this._startIdleBounce()
      this._onEnter = () => this._hoverIn()
      this._onLeave = () => this._hoverOut()
      this._arrowEl.addEventListener("mouseenter", this._onEnter)
      this._arrowEl.addEventListener("mouseleave", this._onLeave)
    }
  }

  disconnect () {
    if (this.observer) this.observer.disconnect()
    this._stopIdleBounce()
    if (this._arrowEl) {
      this._arrowEl.removeEventListener("mouseenter", this._onEnter)
      this._arrowEl.removeEventListener("mouseleave", this._onLeave)
    }
  }

  hide () {
    if (!this.hasArrowTarget) return
    this.arrowTarget.classList.add("opacity-0", "pointer-events-none")
  }

  show () {
    if (!this.hasArrowTarget) return
    this.arrowTarget.classList.remove("opacity-0", "pointer-events-none")
  }

  // ── Idle bounce (remplace le CSS animation-bounce) ────────────────────
  _startIdleBounce () {
    if (prefersReducedMotion()) return
    this._bounceTween = gsap.to(this._arrowEl, {
      y:        10,
      duration: 1,
      ease:     "sine.inOut",
      repeat:   -1,
      yoyo:     true
    })
  }

  _stopIdleBounce () {
    if (this._bounceTween) {
      this._bounceTween.kill()
      this._bounceTween = null
    }
  }

  // ── Hover : nudge vers le bas + snap élastique ────────────────────────
  _hoverIn () {
    if (prefersReducedMotion()) return
    if (this._bounceTween) this._bounceTween.pause()
    gsap.killTweensOf(this._arrowEl)

    const tl = gsap.timeline()
    tl.to(this._arrowEl, { y: 16, scale: 1.1, duration: 0.18, ease: "power2.out" })
      .to(this._arrowEl, { y: 0, scale: 1, duration: 0.7, ease: "elastic.out(1.3, 0.45)" })
  }

  _hoverOut () {
    if (prefersReducedMotion()) return
    gsap.killTweensOf(this._arrowEl)
    gsap.to(this._arrowEl, {
      y:        0,
      scale:    1,
      duration: 0.3,
      ease:     "power2.out",
      onComplete: () => this._startIdleBounce()
    })
  }
}
