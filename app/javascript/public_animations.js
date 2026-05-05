/**
 * Animations GSAP « publiques » : reveal simple au scroll (ScrollTrigger), avec opt-out a11y.
 * Marqueurs : data-gsap-reveal sur un ancêtre, data-gsap-reveal-item sur chaque bloc à animer
 * (sinon : enfants directs :scope > *).
 */
import { prefersReducedMotion } from "lib/gsap/animation_prefs"
import { gsap, gsapScoped, ScrollTrigger } from "lib/gsap/register"

document.addEventListener("turbo:load", initPublicReveals)
document.addEventListener("turbo:frame-load", () => ScrollTrigger.refresh())

function initPublicReveals () {
  const roots = document.querySelectorAll("[data-gsap-reveal]")
  if (roots.length === 0) return

  gsapScoped(() => {
    const triggers = []

    if (prefersReducedMotion()) {
      roots.forEach((root) => {
        const targets = resolveTargets(root)
        gsap.set(targets, { clearProps: "opacity,transform" })
      })
      return () => {}
    }

    roots.forEach((root) => {
      const targets = resolveTargets(root)
      if (targets.length === 0) return

      gsap.set(targets, { autoAlpha: 0, y: 24 })

      const st = ScrollTrigger.create({
        trigger: root,
        start: "top 90%",
        once: true,
        onEnter: () => {
          gsap.to(targets, {
            autoAlpha: 1,
            y: 0,
            duration: 0.48,
            ease: "power2.out",
            overwrite: "auto"
          })
        }
      })
      triggers.push(st)
    })

    return () => {
      triggers.forEach((t) => t.kill())
    }
  }, document.body)
}

function resolveTargets (root) {
  const marked = root.querySelectorAll("[data-gsap-reveal-item]")
  if (marked.length > 0) {
    return gsap.utils.toArray(marked)
  }
  return gsap.utils.toArray(root.querySelectorAll(":scope > *"))
}
