import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleToggle = this.handleToggle.bind(this)
    this.triggers.forEach((trigger) => trigger.addEventListener("click", this.handleToggle))
  }

  disconnect() {
    this.triggers.forEach((trigger) => trigger.removeEventListener("click", this.handleToggle))
  }

  get triggers() {
    return this._triggers ||= Array.from(this.element.querySelectorAll("[data-accordion-target]"))
  }

  handleToggle(event) {
    const trigger = event.currentTarget
    const panel = this.resolvePanel(trigger)
    if (!panel) return

    const expanded = trigger.getAttribute("aria-expanded") === "true"
    trigger.setAttribute("aria-expanded", (!expanded).toString())

    if (expanded) {
      this.hidePanel(panel)
      this.rotateIcon(trigger, true)
    } else {
      this.showPanel(panel)
      this.rotateIcon(trigger, false)
    }
  }

  resolvePanel(trigger) {
    const target = trigger.getAttribute("data-accordion-target")
    if (!target) return null

    if (target.startsWith("#")) {
      return document.getElementById(target.slice(1))
    }

    const ariaControls = trigger.getAttribute("aria-controls")
    if (ariaControls) {
      const element = document.getElementById(ariaControls)
      if (element) return element
    }

    return document.querySelector(target)
  }

  showPanel(panel) {
    panel.classList.remove("hidden")
    panel.removeAttribute("hidden")
  }

  hidePanel(panel) {
    panel.classList.add("hidden")
    panel.setAttribute("hidden", "")
  }

  rotateIcon(trigger, collapsed) {
    const icon = trigger.querySelector("[data-accordion-icon]")
    if (!icon) return

    if (collapsed) {
      icon.classList.add("rotate-180")
    } else {
      icon.classList.remove("rotate-180")
    }
  }
}