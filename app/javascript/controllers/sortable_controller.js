import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this._dragging = null
  }

  dragstart(event) {
    this._dragging = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    requestAnimationFrame(() => event.currentTarget.classList.add("opacity-40"))
  }

  dragend(event) {
    event.currentTarget.classList.remove("opacity-40")
    this._clearIndicators()
    this._dragging = null
  }

  dragover(event) {
    if (!this._dragging) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    const target = this._row(event)
    if (target && target !== this._dragging) {
      this._clearIndicators()
      target.classList.add("ring-1", "ring-inset", "ring-brand-primary/50", "bg-brand-primary/[0.03]")
    }
  }

  dragleave(event) {
    const target = this._row(event)
    if (target) this._clearIndicators()
  }

  drop(event) {
    event.preventDefault()
    const target = this._row(event)
    this._clearIndicators()
    if (!target || target === this._dragging || !this._dragging) return

    const rows = this._rows()
    const from = rows.indexOf(this._dragging)
    const to   = rows.indexOf(target)
    if (from < to) target.after(this._dragging)
    else           target.before(this._dragging)

    this._renumber()
    this._persist()
  }

  _row(event) {
    return event.target.closest("[data-sortable-row]")
  }

  _rows() {
    return [...this.element.querySelectorAll("[data-sortable-row]")]
  }

  _clearIndicators() {
    this._rows().forEach(r => r.classList.remove("ring-1", "ring-inset", "ring-brand-primary/50", "bg-brand-primary/[0.03]"))
  }

  _renumber() {
    this._rows().forEach((row, i) => {
      const el = row.querySelector("[data-sortable-number]")
      if (el) el.textContent = i + 1
    })
  }

  _persist() {
    const ids = this._rows().map(r => r.dataset.id)
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ ids })
    })
  }
}
