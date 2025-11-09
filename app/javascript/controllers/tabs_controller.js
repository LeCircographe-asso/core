import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["trigger", "panel"]
  static values = { initial: String }
  static classes = ["active"]

  connect() {
    this.show(this.initialValue || this.defaultName)
  }

  select(event) {
    event.preventDefault()
    const name = event.currentTarget.dataset.tabsNameValue
    this.show(name)
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
}
