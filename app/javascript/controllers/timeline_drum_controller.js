import { Controller } from "@hotwired/stimulus"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

const STEP_DEG = 20      // écart entre deux années sur le cylindre
const VISIBLE = 3        // années visibles au-dessus / au-dessous de celle de face
const DRAG_PX = 44       // glisser de cette distance = une année
const WHEEL_PX = 60      // cumul de molette pour une année

// Tambour d'années (shared/_timeline_drum). La position de chaque année est posée en variables
// CSS par CSSOM (--tl-angle, --tl-fade) : la CSP refuse les attributs style écrits dans le HTML.
export default class extends Controller {
  static targets = ["drum", "year", "panel", "prev", "next"]
  static values = { index: Number }

  connect () {
    this._wheel = 0
    this.#select(this.indexValue, { animate: false })
  }

  choose (event) {
    if (this._dragged) return
    this.#select(Number(event.currentTarget.dataset.index))
  }

  previous () { this.#select(this.indexValue - 1) }
  next () { this.#select(this.indexValue + 1) }

  key (event) {
    const moves = { ArrowUp: this.indexValue - 1, ArrowDown: this.indexValue + 1, Home: 0, End: this.yearTargets.length - 1 }
    if (!(event.key in moves)) return
    event.preventDefault()
    this.#select(moves[event.key])
    this.yearTargets[this.indexValue].focus({ preventScroll: true })
  }

  // La molette fait tourner le tambour ; arrivée au bout, elle rend la main au défilement de la page.
  wheel (event) {
    const direction = Math.sign(event.deltaY)
    const atEdge = (direction < 0 && this.indexValue === 0) || (direction > 0 && this.indexValue === this.yearTargets.length - 1)
    if (direction === 0 || atEdge) return
    event.preventDefault()
    this._wheel += event.deltaY
    if (Math.abs(this._wheel) < WHEEL_PX) return
    this._wheel = 0
    this.#select(this.indexValue + direction)
  }

  grab (event) {
    if (event.pointerType === "mouse" && event.button !== 0) return
    this._dragStart = { y: event.clientY, index: this.indexValue }
    this._dragged = false
  }

  drag (event) {
    if (!this._dragStart) return
    const dy = event.clientY - this._dragStart.y
    if (Math.abs(dy) > 6 && !this._dragged) {
      this._dragged = true
      this.drumTarget.setPointerCapture(event.pointerId)
    }
    if (this._dragged) this.#select(this._dragStart.index - Math.round(dy / DRAG_PX))
  }

  release () {
    this._dragStart = null
    // laisse passer le clic qui suit un glisser sans changer d'année
    setTimeout(() => { this._dragged = false }, 0)
  }

  #select (index, { animate = true } = {}) {
    const last = this.yearTargets.length - 1
    index = Math.max(0, Math.min(last, index))
    const changed = index !== this.indexValue
    this.indexValue = index

    this.drumTarget.classList.toggle("tl-drum--still", !animate || prefersReducedMotion())
    this.yearTargets.forEach((year, i) => {
      const offset = i - index
      const active = offset === 0
      year.style.setProperty("--tl-angle", `${-offset * STEP_DEG}deg`)
      year.style.setProperty("--tl-fade", Math.abs(offset) > VISIBLE ? 0 : 1 - Math.abs(offset) * 0.26)
      year.toggleAttribute("data-active", active)
      year.setAttribute("aria-selected", active)
      year.tabIndex = active ? 0 : -1
      year.inert = Math.abs(offset) > VISIBLE
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
      if (i === index && changed && animate && !prefersReducedMotion()) {
        panel.classList.remove("tl-ribbon-panel--enter")
        void panel.offsetWidth // relance l'animation d'entrée
        panel.classList.add("tl-ribbon-panel--enter")
      }
    })
    if (this.hasPrevTarget) this.prevTarget.disabled = index === 0
    if (this.hasNextTarget) this.nextTarget.disabled = index === last
  }
}
