import { Controller } from "@hotwired/stimulus"
import { openRichConfirmModal } from "confirm_modal"

export default class extends Controller {
  static targets = ["panel", "form", "email", "emailConfirm", "code", "error"]
  static values = {
    currentEmail: String,
    blankMessage: String,
    mismatchMessage: String,
    unchangedMessage: String,
    previewTitle: String,
    previewIntro: String,
    previewConfirmLabel: String,
    previewBackLabel: String,
    invalidCodeMessage: String
  }

  connect() {
    this.onSubmitEnd = this.handleSubmitEnd.bind(this)
    if (this.hasFormTarget) {
      this.formTarget.addEventListener("turbo:submit-end", this.onSubmitEnd)
    }
  }

  disconnect() {
    if (this.hasFormTarget) {
      this.formTarget.removeEventListener("turbo:submit-end", this.onSubmitEnd)
    }
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    if (!this.hasPanelTarget) return
    this.clearError()
    this.panelTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    requestAnimationFrame(() => {
      if (this.hasEmailTarget) this.emailTarget.focus()
    })
  }

  close(event) {
    event?.preventDefault()
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("hidden")
    document.body.style.overflow = ""
    this.clearError()
    if (this.hasFormTarget) this.formTarget.reset()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  async requestCode(event) {
    event.preventDefault()
    this.clearError()

    const payload = this.validatedPayload()
    if (!payload) return

    const escaped = this.escapeHtml(payload.nextRaw)
    const confirmed = await openRichConfirmModal({
      title: this.previewTitleValue,
      introText: this.previewIntroValue,
      htmlBody: `<p class="font-medium text-gray-900">${escaped}</p>`,
      confirmText: this.previewConfirmLabelValue,
      cancelText: this.previewBackLabelValue
    })

    if (!confirmed) return

    if (this.hasCodeTarget) this.codeTarget.value = ""
    this.formTarget.requestSubmit()
  }

  // Backward-compatible action name used by previous modal button wiring.
  async submitWithConfirmation(event) {
    await this.requestCode(event)
  }

  confirmCode(event) {
    event.preventDefault()
    this.clearError()

    const payload = this.validatedPayload()
    if (!payload) return

    const code = this.hasCodeTarget ? this.codeTarget.value.trim() : ""
    if (!/^\d{6}$/.test(code)) {
      this.showError(this.invalidCodeMessageValue || "Invalid code format.")
      return
    }

    this.formTarget.requestSubmit()
  }

  handleSubmitEnd(event) {
    if (event.detail.success) this.close()
  }

  showError(message) {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  clearError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  validatedPayload() {
    const nextRaw = this.emailTarget.value.trim()
    const confirmRaw = this.emailConfirmTarget.value.trim()
    const next = nextRaw.toLowerCase()
    const confirm = confirmRaw.toLowerCase()
    const current = (this.currentEmailValue || "").trim().toLowerCase()

    if (!next || !confirm) {
      this.showError(this.blankMessageValue || this.mismatchMessageValue)
      return null
    }

    if (next !== confirm) {
      this.showError(this.mismatchMessageValue)
      return null
    }

    if (next === current) {
      this.showError(this.unchangedMessageValue)
      return null
    }

    return { nextRaw }
  }
}
