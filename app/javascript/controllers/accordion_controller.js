import { Controller } from "@hotwired/stimulus"
import { gsap } from "lib/gsap/register"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

export default class extends Controller {
  // animate: false par défaut → navbar inchangée
  // animate: true  → slide GSAP sur les accordéons publics
  static values = { animate: { type: Boolean, default: false } }

  connect () {
    this.handleToggle = this.handleToggle.bind(this)
    this.triggers.forEach((trigger) => trigger.addEventListener("click", this.handleToggle))
  }

  disconnect () {
    this.triggers.forEach((trigger) => trigger.removeEventListener("click", this.handleToggle))
  }

  get triggers () {
    return this._triggers ||= Array.from(
      this.element.querySelectorAll("[data-accordion-target]")
    )
  }

  handleToggle (event) {
    const trigger  = event.currentTarget
    const panel    = this.resolvePanel(trigger)
    if (!panel) return

    const expanded = trigger.getAttribute("aria-expanded") === "true"
    trigger.setAttribute("aria-expanded", (!expanded).toString())

    if (expanded) {
      this.animateValue ? this._slideUp(panel, trigger) : this.hidePanel(panel)
      this.rotateIcon(trigger, true)
    } else {
      this.animateValue ? this._slideDown(panel, trigger) : this.showPanel(panel)
      this.rotateIcon(trigger, false)
    }
  }

  resolvePanel (trigger) {
    const target = trigger.getAttribute("data-accordion-target")
    if (!target) return null
    if (target.startsWith("#")) return document.getElementById(target.slice(1))
    const ariaControls = trigger.getAttribute("aria-controls")
    if (ariaControls) {
      const el = document.getElementById(ariaControls)
      if (el) return el
    }
    return document.querySelector(target)
  }

  // ── Comportement historique (navbar) ───────────────────────────────────
  showPanel (panel) {
    panel.classList.remove("hidden")
    panel.removeAttribute("hidden")
  }

  hidePanel (panel) {
    panel.classList.add("hidden")
    panel.setAttribute("hidden", "")
  }

  rotateIcon (trigger, collapsed) {
    const icon = trigger.querySelector("[data-accordion-icon]")
    if (!icon) return
    collapsed ? icon.classList.add("rotate-180") : icon.classList.remove("rotate-180")
  }

  // ── Slide animé (pages publiques uniquement) ────────────────────────────
  _slideDown (panel, trigger) {
    // annulation d'un éventuel slide-up en cours
    gsap.killTweensOf(panel)

    panel.classList.remove("hidden")
    panel.removeAttribute("hidden")

    if (prefersReducedMotion()) return

    this._animateIcon(trigger, false)

    gsap.fromTo(panel,
      { height: 0, opacity: 0, overflow: "hidden" },
      {
        height:   "auto",
        opacity:  1,
        duration: 0.38,
        ease:     "power2.out",
        onComplete () { gsap.set(panel, { clearProps: "height,overflow,opacity" }) }
      }
    )
  }

  _slideUp (panel, trigger) {
    gsap.killTweensOf(panel)

    if (prefersReducedMotion()) {
      this.hidePanel(panel)
      return
    }

    this._animateIcon(trigger, true)

    gsap.to(panel, {
      height:   0,
      opacity:  0,
      overflow: "hidden",
      duration: 0.28,
      ease:     "power2.in",
      onComplete () {
        panel.classList.add("hidden")
        panel.setAttribute("hidden", "")
        gsap.set(panel, { clearProps: "height,overflow,opacity" })
      }
    })
  }

  _animateIcon (trigger, toCollapsed) {
    const icon = trigger.querySelector("[data-accordion-icon]")
    if (!icon) return
    // rotation fluide via GSAP (remplace la transition Tailwind)
    gsap.to(icon, {
      rotation: toCollapsed ? 180 : 0,
      duration: 0.3,
      ease: "power2.inOut"
    })
  }
}
