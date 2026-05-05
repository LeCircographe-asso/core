import { Controller } from "@hotwired/stimulus"
import { gsap, ScrollTrigger } from "lib/gsap/register"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

// Connects to data-controller="timeline"
export default class extends Controller {
  static targets = ["step", "line"]

  connect () {
    this._ctx = null
    // Defer one frame so Propshaft-fingerprinted assets are fully laid out
    requestAnimationFrame(() => this._animate())
  }

  disconnect () {
    if (this._ctx) {
      this._ctx.revert()
      this._ctx = null
    }
  }

  _animate () {
    const steps = this.stepTargets
    const line  = this.hasLineTarget ? this.lineTarget : null

    // ── a11y : pas d'animation si l'utilisateur le demande ────────────────
    if (prefersReducedMotion()) {
      steps.forEach(el => el.classList.add("tl-step--visible"))
      if (line) gsap.set(line, { scaleY: 1 })
      return
    }

    // Contexte GSAP : toutes les instances ScrollTrigger + tweens seront
    // révoquées par ctx.revert() dans disconnect() (GSAP 3.11+).
    this._ctx = gsap.context(() => {
      // ── 1. Ligne verticale — croît avec le scroll (scrub) ──────────────
      if (line) {
        gsap.set(line, { scaleY: 0 })
        ScrollTrigger.create({
          trigger: this.element,
          start: "top 82%",
          end: "bottom 60%",
          scrub: 1.6,
          onUpdate: (self) => gsap.set(line, { scaleY: self.progress })
        })
      }

      // ── 2. Chaque étape : pastille pop + carte glisse vers le haut ──────
      steps.forEach((step) => {
        const card   = step.querySelector(".tl-card")
        const dot    = step.querySelector(".tl-dot")
        const ring   = step.querySelector(".tl-dot__ring")
        const status = step.dataset.status || "past"

        // État initial invisible
        gsap.set(dot, { scale: 0, opacity: 0 })
        gsap.set(card, { opacity: 0, y: 20 })

        ScrollTrigger.create({
          trigger: step,
          start: "top 90%",
          once: true,
          onEnter () {
            step.classList.add("tl-step--visible")

            // Pastille : pop entrant
            gsap.to(dot, {
              scale: 1,
              opacity: 1,
              duration: 0.45,
              ease: "back.out(2.5)"
            })

            // Carte : glisse vers le haut + opacité
            gsap.to(card, {
              opacity: status === "future" ? 0.52 : 1,
              y: 0,
              duration: 0.55,
              delay: 0.1,
              ease: "power3.out"
            })

            // Étape présente : anneau pulsant (repeat infini)
            if (status === "present" && ring) {
              gsap.fromTo(ring,
                { scale: 1, opacity: 0.65 },
                {
                  scale: 2.5,
                  opacity: 0,
                  duration: 1.6,
                  ease: "power1.out",
                  repeat: -1,
                  repeatDelay: 0.5
                }
              )
            }
          }
        })
      })
    }, this.element)
  }
}
