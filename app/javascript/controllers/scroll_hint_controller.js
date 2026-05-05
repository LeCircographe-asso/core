import { Controller } from "@hotwired/stimulus"
import { gsap } from "lib/gsap/register"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

// Connects to data-controller="scroll-hint"
export default class extends Controller {
  static targets = ["arrow"]
  static values  = { sectionId: String }

  connect () {
    this._arrowEl = this.element.querySelector(".scroll-arrow")
    this._heroSection = this.element.closest("section")
    this._visibilityRaf = null
    this._onScroll = () => this._queueVisibilitySync()
    window.addEventListener("scroll", this._onScroll, { passive: true })
    window.addEventListener("resize", this._onScroll, { passive: true })

    if (this._arrowEl) {
      this._startIdleBounce()
      this._onEnter = () => this._hoverIn()
      this._onLeave = () => this._hoverOut()
      this._arrowEl.addEventListener("mouseenter", this._onEnter)
      this._arrowEl.addEventListener("mouseleave", this._onLeave)
    }

    this._syncVisibility()
  }

  disconnect () {
    window.removeEventListener("scroll", this._onScroll)
    window.removeEventListener("resize", this._onScroll)
    if (this._visibilityRaf) {
      cancelAnimationFrame(this._visibilityRaf)
      this._visibilityRaf = null
    }
    this._stopIdleBounce()
    if (this._arrowEl) {
      this._arrowEl.removeEventListener("mouseenter", this._onEnter)
      this._arrowEl.removeEventListener("mouseleave", this._onLeave)
    }
  }

  scrollToSection (event) {
    const section = this._targetSection()
    if (!section) return

    if (event) event.preventDefault()

    const targetTop = this._targetTop(section)
    this.hide()

    window.scrollTo({
      top: Math.max(targetTop, 0),
      behavior: prefersReducedMotion() ? "auto" : "smooth"
    })
  }

  hide () {
    if (!this.hasArrowTarget) return
    this.arrowTarget.classList.add("opacity-0", "pointer-events-none")
  }

  show () {
    if (!this.hasArrowTarget) return
    this.arrowTarget.classList.remove("opacity-0", "pointer-events-none")
  }

  _syncVisibility () {
    if (!this.hasArrowTarget) return

    if (!this._heroSection) {
      this.show()
      return
    }

    const heroBottom = this._heroSection.getBoundingClientRect().bottom
    const header = document.querySelector("header nav")
    const headerHeight = header ? header.getBoundingClientRect().height : 0
    const cutoff = headerHeight + 120

    if (heroBottom <= cutoff) {
      this.hide()
    } else {
      this.show()
    }
  }

  _queueVisibilitySync () {
    if (this._visibilityRaf) return

    this._visibilityRaf = requestAnimationFrame(() => {
      this._visibilityRaf = null
      this._syncVisibility()
    })
  }

  _targetSection () {
    if (!this.sectionIdValue) return null
    return document.getElementById(this.sectionIdValue)
  }

  _targetTop (section) {
    const headerHeight = this._headerOffset()
    const styles = window.getComputedStyle(section)
    const scrollMarginTop = parseFloat(styles.scrollMarginTop || "0") || 0
    const sectionTop = section.getBoundingClientRect().top + window.scrollY - Math.max(headerHeight, scrollMarginTop)

    if (!this._heroSection) return sectionTop

    const heroBottom = this._heroSection.getBoundingClientRect().bottom + window.scrollY
    const heroExitTop = heroBottom - headerHeight + 24

    return Math.max(sectionTop, heroExitTop)
  }

  _headerOffset () {
    const fixedHeader = document.querySelector("header")
    if (!fixedHeader) return 16

    return fixedHeader.getBoundingClientRect().height + 16
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
