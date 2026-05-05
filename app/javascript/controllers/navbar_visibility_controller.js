import { Controller } from "@hotwired/stimulus"
import { gsap, ScrollTrigger } from "lib/gsap/register"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 18 },
    topOffset: { type: Number, default: 12 }
  }

  connect () {
    this.beforeCache = this.handleBeforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this.beforeCache)

    this.isPrimingScroll = true
    this.isHidden = false
    this.lastScrollY = window.scrollY || 0
    this.accumulatedDelta = 0
    this.lastDirection = 0
    const shouldWaitForHero = this.waitForHomeHeroReveal()

    if (shouldWaitForHero) {
      this.primeHiddenState()
    } else {
      this.resetVisualState()
    }

    this.updateTopState(this.lastScrollY)

    this.scrollTrigger = ScrollTrigger.create({
      start: 0,
      end: "max",
      onUpdate: self => this.handleScroll(self.scroll())
    })

    if (shouldWaitForHero) {
      this._onHomeHeroReady = () => this.revealNavbar()
      document.addEventListener("home:hero-ready", this._onHomeHeroReady, { once: true })
      this.revealFallbackTimer = window.setTimeout(() => this.revealNavbar(), 3200)
      this.primeInitialScrollSync()
      return
    }

    this.revealNavbar()
    this.primeInitialScrollSync()
  }

  disconnect () {
    this.scrollTrigger?.kill()
    document.removeEventListener("turbo:before-cache", this.beforeCache)
    if (this.initialScrollSyncFrame) {
      window.cancelAnimationFrame(this.initialScrollSyncFrame)
      this.initialScrollSyncFrame = null
    }
    if (this.initialScrollSyncFrameNested) {
      window.cancelAnimationFrame(this.initialScrollSyncFrameNested)
      this.initialScrollSyncFrameNested = null
    }
    if (this.revealFallbackTimer) {
      window.clearTimeout(this.revealFallbackTimer)
      this.revealFallbackTimer = null
    }
    if (this._onHomeHeroReady) {
      document.removeEventListener("home:hero-ready", this._onHomeHeroReady)
      this._onHomeHeroReady = null
    }
  }

  handleScroll (currentScrollY) {
    if (this.isPrimingScroll) {
      this.resetScrollState(currentScrollY)
      this.updateTopState(currentScrollY)
      return
    }

    if (this.mobileMenuOpen()) {
      this.show()
      this.resetScrollState(currentScrollY)
      this.updateTopState(currentScrollY)
      return
    }

    const delta = currentScrollY - this.lastScrollY
    if (delta === 0) {
      this.updateTopState(currentScrollY)
      return
    }

    const direction = Math.sign(delta)
    if (direction !== this.lastDirection) {
      this.accumulatedDelta = 0
      this.lastDirection = direction
    }

    this.accumulatedDelta += delta
    this.updateTopState(currentScrollY)

    if (currentScrollY <= this.topOffsetValue) {
      this.show()
      this.resetScrollState(currentScrollY)
      return
    }

    const hideThreshold = this.thresholdValue
    const showThreshold = Math.max(8, Math.round(this.thresholdValue * 0.5))

    if (!this.isHidden && this.accumulatedDelta >= hideThreshold) {
      this.hide()
      this.resetScrollState(currentScrollY, 1)
      return
    }

    if (this.isHidden && this.accumulatedDelta <= -showThreshold) {
      this.show()
      this.resetScrollState(currentScrollY, -1)
      return
    }

    this.lastScrollY = currentScrollY
  }

  resetScrollState (currentScrollY, direction = 0) {
    this.lastScrollY = currentScrollY
    this.accumulatedDelta = 0
    this.lastDirection = direction
  }

  hide () {
    if (this.isHidden) return
    this.isHidden = true

    gsap.to(this.element, {
      yPercent: -100,
      duration: 0.22,
      ease: "power2.out",
      overwrite: "auto"
    })
  }

  show () {
    if (!this.isHidden) return
    this.isHidden = false

    gsap.to(this.element, {
      yPercent: 0,
      duration: 0.26,
      ease: "power2.out",
      overwrite: "auto"
    })
  }

  updateTopState (scrollY) {
    this.element.dataset.navState = scrollY <= this.topOffsetValue ? "top" : "scrolled"
  }

  mobileMenuOpen () {
    const menu = this.element.querySelector("#navbar-mobile")
    return menu ? !menu.classList.contains("hidden") : false
  }

  revealNavbar () {
    if (this.revealFallbackTimer) {
      window.clearTimeout(this.revealFallbackTimer)
      this.revealFallbackTimer = null
    }

    gsap.killTweensOf(this.element)
    this.element.dataset.navReady = "true"

    if (prefersReducedMotion()) {
      gsap.set(this.element, { y: 0, yPercent: 0, autoAlpha: 1, clearProps: "transform,opacity,visibility" })
      return
    }

    gsap.fromTo(
      this.element,
      { y: -10, yPercent: 0, autoAlpha: 0 },
      { y: 0, yPercent: 0, autoAlpha: 1, duration: 0.24, ease: "power2.out", overwrite: "auto", clearProps: "transform,opacity,visibility" }
    )
  }

  waitForHomeHeroReveal () {
    return document.body.classList.contains("home-index") &&
      document.querySelector("[data-home-animations-scope]") &&
      !prefersReducedMotion()
  }

  handleBeforeCache () {
    this.scrollTrigger?.kill()
    this.isPrimingScroll = false
    if (this.revealFallbackTimer) {
      window.clearTimeout(this.revealFallbackTimer)
      this.revealFallbackTimer = null
    }
    if (this.initialScrollSyncFrame) {
      window.cancelAnimationFrame(this.initialScrollSyncFrame)
      this.initialScrollSyncFrame = null
    }
    if (this.initialScrollSyncFrameNested) {
      window.cancelAnimationFrame(this.initialScrollSyncFrameNested)
      this.initialScrollSyncFrameNested = null
    }

    this.isHidden = false
    this.element.dataset.navReady = "true"
    this.element.dataset.navState = "top"
    this.resetVisualState()
  }

  resetVisualState () {
    gsap.killTweensOf(this.element)
    gsap.set(this.element, {
      y: 0,
      yPercent: 0,
      autoAlpha: 1,
      clearProps: "transform,opacity,visibility"
    })
  }

  primeHiddenState () {
    gsap.killTweensOf(this.element)
    gsap.set(this.element, {
      y: 0,
      yPercent: 0,
      clearProps: "transform"
    })
  }

  primeInitialScrollSync () {
    if (this.initialScrollSyncFrame) {
      window.cancelAnimationFrame(this.initialScrollSyncFrame)
    }
    if (this.initialScrollSyncFrameNested) {
      window.cancelAnimationFrame(this.initialScrollSyncFrameNested)
    }

    this.initialScrollSyncFrame = window.requestAnimationFrame(() => {
      this.initialScrollSyncFrameNested = window.requestAnimationFrame(() => {
        const currentScrollY = window.scrollY || window.pageYOffset || 0
        this.show()
        this.resetScrollState(currentScrollY)
        this.updateTopState(currentScrollY)
        this.isPrimingScroll = false
        this.initialScrollSyncFrame = null
        this.initialScrollSyncFrameNested = null
      })
    })
  }
}
