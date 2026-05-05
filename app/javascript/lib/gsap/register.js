/**
 * GSAP 3 (vendor/javascript/gsap, npm 3.15.0) — enregistrement unique des plugins + cycle de vie Turbo.
 * Pas de CDN : voir docs/development/assets.md.
 */
import gsap from "gsap"
import ScrollTrigger from "gsap/ScrollTrigger"
import ScrollSmoother from "gsap/ScrollSmoother"
import Flip from "gsap/Flip"
import Observer from "gsap/Observer"
import Draggable from "gsap/Draggable"
import MotionPathPlugin from "gsap/MotionPathPlugin"
import CustomEase from "gsap/CustomEase"
import TextPlugin from "gsap/TextPlugin"

gsap.registerPlugin(
  ScrollTrigger,
  ScrollSmoother,
  Flip,
  Observer,
  Draggable,
  MotionPathPlugin,
  CustomEase,
  TextPlugin
)

/** Contextes créés via gsapScoped / trackGsapContext — revert avant mise en cache Turbo */
const trackedContexts = []

export function trackGsapContext (ctx) {
  trackedContexts.push(ctx)
  return ctx
}

/** Wrapper recommandé autour des animations par page ou bloc (revert groupé sur before-cache). */
export function gsapScoped (setup, scope) {
  const ctx = gsap.context(setup, scope)
  trackedContexts.push(ctx)
  return ctx
}

function revertTrackedContexts () {
  while (trackedContexts.length) {
    trackedContexts.pop().revert()
  }
}

function cleanupBeforeTurboCache () {
  revertTrackedContexts()

  const smoother = ScrollSmoother.get()
  if (smoother) smoother.kill()

  ScrollTrigger.getAll().forEach((st) => st.kill())
  ScrollTrigger.clearScrollMemory()

  gsap.globalTimeline.clear()
}

let lifecycleInstalled = false

export function installGsapTurboLifecycle () {
  if (lifecycleInstalled) return
  lifecycleInstalled = true
  document.addEventListener("turbo:before-cache", cleanupBeforeTurboCache)
}

installGsapTurboLifecycle()

export {
  gsap,
  ScrollTrigger,
  ScrollSmoother,
  Flip,
  Observer,
  Draggable,
  MotionPathPlugin,
  CustomEase,
  TextPlugin
}
