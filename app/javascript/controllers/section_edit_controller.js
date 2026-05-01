import { Controller } from "@hotwired/stimulus"
import { openRichConfirmModal } from "confirm_modal"

// data-controller="section-edit"
export default class extends Controller {
  static targets = ["read", "edit", "save", "editButton", "cancelButton", "field", "protectedAction"]
  static values = {
    editing: Boolean,
    warningMessage: String,
    modifyLabel: String,
    acceptLabel: String,
    recapIntro: String,
    recapTitle: String,
    recapConfirmLabel: String,
    recapBackLabel: String
  }

  connect() {
    this.preflight = false
    this.initialValues = this.fieldTargets.map((field) => this.fieldValue(field))
    this.beforeUnloadHandler = (event) => {
      if (!this.hasUnsavedChanges()) return
      event.preventDefault()
      event.returnValue = this.warningMessageValue || "Vous avez des modifications non enregistrées."
    }
    window.addEventListener("beforeunload", this.beforeUnloadHandler)
    this.render()
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
  }

  handlePrimaryAction(event) {
    event.preventDefault()
    if (this.editingValue) return

    if (this.preflight) {
      void this.openRecapAndContinue()
      return
    }

    this.preflight = true
    this.render()
  }

  async openRecapAndContinue() {
    const summaryHtml = this.buildRecapListHtml()
    const confirmed = await openRichConfirmModal({
      title: this.recapTitleValue,
      introText: this.recapIntroValue,
      htmlBody: summaryHtml,
      confirmText: this.recapConfirmLabelValue,
      cancelText: this.recapBackLabelValue
    })

    if (!confirmed) return

    this.preflight = false
    this.editingValue = true
    this.initialValues = this.fieldTargets.map((field) => this.fieldValue(field))
    this.render()
    this.updateSaveState()
  }

  cancelEdit(event) {
    event.preventDefault()

    if (this.preflight) {
      this.preflight = false
      this.render()
      return
    }

    this.resetFields()
    this.editingValue = false
    this.render()
  }

  handleInput() {
    this.updateSaveState()
  }

  beforeSubmit() {
    if (!this.hasSaveTarget) return
    this.saveTarget.disabled = true
    this.saveTarget.textContent = this.saveTarget.dataset.loadingText || "Enregistrement..."
  }

  render() {
    const editing = this.editingValue
    const preflight = this.preflight

    this.readTargets.forEach((element) => element.classList.toggle("hidden", editing))
    this.editTargets.forEach((element) => element.classList.toggle("hidden", !editing))

    if (this.hasEditButtonTarget) {
      this.editButtonTarget.classList.toggle("hidden", editing)
      if (!editing) {
        const primary = preflight ? this.acceptLabelValue : this.modifyLabelValue
        this.editButtonTarget.textContent = primary
      }
    }

    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.toggle("hidden", !editing && !preflight)
    }

    const blockProtected = editing || preflight
    this.protectedActionTargets.forEach((element) => {
      element.classList.toggle("opacity-50", blockProtected)
      element.classList.toggle("pointer-events-none", blockProtected)
      element.setAttribute("aria-disabled", blockProtected ? "true" : "false")
    })
  }

  updateSaveState() {
    if (!this.hasSaveTarget) return
    const changed = this.fieldTargets.some((field, index) => this.fieldValue(field) !== this.initialValues[index])
    this.saveTarget.disabled = !changed
    this.saveTarget.classList.toggle("opacity-50", !changed)
    this.saveTarget.classList.toggle("cursor-not-allowed", !changed)
  }

  resetFields() {
    this.fieldTargets.forEach((field, index) => {
      const initial = this.initialValues[index]
      if (field.type === "checkbox") {
        field.checked = initial === "true"
      } else {
        field.value = initial
      }
    })
  }

  fieldValue(field) {
    return field.type === "checkbox" ? String(field.checked) : (field.value || "")
  }

  hasUnsavedChanges() {
    if (!this.editingValue) return false
    return this.fieldTargets.some((field, index) => this.fieldValue(field) !== this.initialValues[index])
  }

  escapeHtml(text) {
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }

  buildRecapListHtml() {
    const root = this.readTargets[0]
    if (!root) return ""

    const rows = root.querySelectorAll(":scope > div.flex")
    if (!rows.length) return ""

    const items = [...rows].map((row) => {
      const spans = row.querySelectorAll(":scope > span")
      if (spans.length < 2) return ""

      const label = this.escapeHtml(spans[0].textContent.trim())
      const value = this.escapeHtml(spans[1].textContent.trim())
      return `<li class="flex justify-between gap-3 py-1.5 border-b border-gray-100 last:border-0"><span class="text-gray-600">${label}</span><span class="font-medium text-right">${value}</span></li>`
    }).filter(Boolean)

    if (!items.length) return ""

    return `<ul class="list-none space-y-0">${items.join("")}</ul>`
  }
}
