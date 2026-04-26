import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["trigger", "panel"]
  static values = { initial: String, useHash: Boolean }
  static classes = ["active"]

  connect() {
    const initialName = this.initialValue || this.defaultName
    const hashName = this.useHashValue ? this.nameFromHash() : null
    this.show(hashName || initialName)
  }

  select(event) {
    event.preventDefault()
    const name = event.currentTarget.dataset.tabsNameValue
    this.show(name)
    if (this.useHashValue) {
      window.location.hash = name
    }
  }

  show(name) {
    this.triggerTargets.forEach(trigger => {
      const selected = trigger.dataset.tabsNameValue === name
      trigger.classList.toggle(this.activeClass, selected)
      trigger.setAttribute("aria-selected", selected)
      trigger.setAttribute("tabindex", selected ? "0" : "-1")
    })

    this.panelTargets.forEach(panel => {
      const selected = panel.dataset.tabsNameValue === name
      panel.classList.toggle("hidden", !selected)
      panel.setAttribute("aria-hidden", (!selected).toString())
    })
  }

  get defaultName() {
    return this.triggerTargets[0]?.dataset.tabsNameValue
  }

  nameFromHash() {
    const hash = window.location.hash.replace("#", "")
    if (!hash) return null
    const names = this.triggerTargets.map(trigger => trigger.dataset.tabsNameValue)
    return names.includes(hash) ? hash : null
  }
}
