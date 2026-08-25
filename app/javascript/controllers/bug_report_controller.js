import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "dialog"]

  connect() {
    this.keydownHandler = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydownHandler)
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    if (!this.hasPanelTarget) return

    this.previousFocus = document.activeElement
    this.panelTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.keydownHandler)

    requestAnimationFrame(() => {
      if (this.hasDialogTarget) this.dialogTarget.focus()
    })
  }

  close(event) {
    event?.preventDefault()
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.add("hidden")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.keydownHandler)

    if (this.previousFocus && typeof this.previousFocus.focus === "function") {
      this.previousFocus.focus()
    }
    this.previousFocus = null
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close(event)
  }
}
