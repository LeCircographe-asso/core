/**
 * Transition « novatrice » légère : à chaque Turbo visit, le bloc principal public
 * monte en fondu avec un léger flou (plus prononcé sur mobile / petite largeur).
 * — Évite la page d’accueil (hero GSAP déjà).
 * — Hors admin / préfère réduire les mouvements.
 */
import { prefersReducedMotion } from "lib/gsap/animation_prefs"
import { gsap, gsapScoped } from "lib/gsap/register"

document.addEventListener("turbo:load", runPublicMainReveal)

function runPublicMainReveal () {
  if (prefersReducedMotion()) return
  if (document.querySelector(".admin-layout")) return

  const shell = document.querySelector("[data-turbo-page-shell]")
  if (!shell) return

  if (document.body.classList.contains("home-index")) return

  const narrow = window.matchMedia("(max-width: 843px)").matches
  const coarse = window.matchMedia("(pointer: coarse)").matches
  const mobileish = narrow || coarse

  gsapScoped(() => {
    gsap.from(shell, {
      y: mobileish ? 36 : 14,
      opacity: 0,
      filter: mobileish ? "blur(10px)" : "blur(5px)",
      duration: mobileish ? 0.48 : 0.35,
      ease: "power3.out",
      onComplete: () => {
        gsap.set(shell, { clearProps: "filter" })
      }
    })
    return () => {}
  }, shell)
}
