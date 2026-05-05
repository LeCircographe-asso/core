/**
 * Aligné sur home_animations.js : même média query pour réduire les animations.
 * À réutiliser depuis les futurs contrôleurs Stimulus / séquences GSAP.
 */
export function prefersReducedMotion () {
  return typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
}
