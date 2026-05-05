/**
 * Entrée esbuild uniquement — regénérer : bundle exec rake gsap:bootstrap
 * Ne pas importer ce fichier depuis l’app ; utiliser importmap → gsap-bootstrap.js
 */
import gsap from "../../../../vendor/javascript/gsap/index.js"
import ScrollTrigger from "../../../../vendor/javascript/gsap/ScrollTrigger.js"
import ScrollSmoother from "../../../../vendor/javascript/gsap/ScrollSmoother.js"
import Flip from "../../../../vendor/javascript/gsap/Flip.js"
import Observer from "../../../../vendor/javascript/gsap/Observer.js"
import Draggable from "../../../../vendor/javascript/gsap/Draggable.js"
import MotionPathPlugin from "../../../../vendor/javascript/gsap/MotionPathPlugin.js"
import CustomEase from "../../../../vendor/javascript/gsap/CustomEase.js"
import TextPlugin from "../../../../vendor/javascript/gsap/TextPlugin.js"

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

const trackedContexts = []

export function trackGsapContext (ctx) {
  trackedContexts.push(ctx)
  return ctx
}

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
