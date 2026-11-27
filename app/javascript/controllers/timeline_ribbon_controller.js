import { Controller } from "@hotwired/stimulus"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

// Ruban d'années (shared/_timeline_ribbon) : l'année au centre du ruban est sélectionnée et
// sa carte s'affiche. On change d'année en faisant glisser le ruban, en touchant une année,
// avec les flèches, en glissant la carte ou au clavier (← → Début Fin).
export default class extends Controller {
  static targets = ["track", "year", "panel", "prev", "next"]
  static values = { index: Number }

  connect () {
    this.#select(this.indexValue, { scroll: "instant" })
  }

  disconnect () {
    clearTimeout(this._settle)
  }

  choose (event) {
    this.#select(Number(event.currentTarget.dataset.index))
  }

  previous () { this.#select(this.indexValue - 1) }
  next () { this.#select(this.indexValue + 1) }

  key (event) {
    const moves = { ArrowLeft: this.indexValue - 1, ArrowRight: this.indexValue + 1, Home: 0, End: this.yearTargets.length - 1 }
    if (!(event.key in moves)) return
    event.preventDefault()
    this.#select(moves[event.key])
    this.yearTargets[this.indexValue].focus({ preventScroll: true })
  }

  // Ruban glissé au doigt : une fois le défilement posé, l'année la plus proche du centre est choisie.
  scrolled () {
    if (this._programmatic) return
    clearTimeout(this._settle)
    this._settle = setTimeout(() => this.#select(this.#centeredIndex(), { scroll: false }), 120)
  }

  touchStart (event) {
    this._touchX = event.changedTouches[0].clientX
  }

  touchEnd (event) {
    if (this._touchX == null) return
    const dx = event.changedTouches[0].clientX - this._touchX
    this._touchX = null
    if (Math.abs(dx) < 40) return
    this.#select(this.indexValue + (dx < 0 ? 1 : -1))
  }

  #select (index, { scroll = "smooth" } = {}) {
    const last = this.yearTargets.length - 1
    index = Math.max(0, Math.min(last, index))
    const changed = index !== this.indexValue
    this.indexValue = index

    this.yearTargets.forEach((year, i) => {
      const active = i === index
      year.toggleAttribute("data-active", active)
      year.setAttribute("aria-selected", active)
      year.tabIndex = active ? 0 : -1
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
      if (i === index && changed && !prefersReducedMotion()) {
        panel.classList.remove("tl-ribbon-panel--enter")
        void panel.offsetWidth // relance l'animation d'entrée
        panel.classList.add("tl-ribbon-panel--enter")
      }
    })
    if (this.hasPrevTarget) this.prevTarget.disabled = index === 0
    if (this.hasNextTarget) this.nextTarget.disabled = index === last

    if (scroll) this.#center(this.yearTargets[index], scroll)
  }

  #center (year, mode) {
    const track = this.trackTarget
    const left = year.offsetLeft - (track.clientWidth - year.offsetWidth) / 2
    this._programmatic = true
    track.scrollTo({ left, behavior: mode === "smooth" && !prefersReducedMotion() ? "smooth" : "instant" })
    clearTimeout(this._unlock)
    this._unlock = setTimeout(() => { this._programmatic = false }, 450)
  }

  #centeredIndex () {
    const track = this.trackTarget
    const middle = track.scrollLeft + track.clientWidth / 2
    let best = 0
    let bestDistance = Infinity
    this.yearTargets.forEach((year, i) => {
      const distance = Math.abs(year.offsetLeft + year.offsetWidth / 2 - middle)
      if (distance < bestDistance) { best = i; bestDistance = distance }
    })
    return best
  }
}
