/**
 * Entrée esbuild uniquement — regénérer : bundle exec rake gsap:bootstrap
 * Ne pas importer ce fichier depuis l’app ; utiliser importmap → gsap-bootstrap.js
 */
import gsap from "../../../../vendor/javascript/gsap/index.js"
import ScrollTrigger from "../../../../vendor/javascript/gsap/ScrollTrigger.js"

// Basique et lisible : on n'enregistre que les plugins réellement utilisés.
gsap.registerPlugin(ScrollTrigger)

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
  ScrollTrigger
}
