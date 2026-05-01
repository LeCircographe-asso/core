import { Controller } from "@hotwired/stimulus"
import { openRichConfirmModal } from "confirm_modal"

// data-controller="section-edit"
export default class extends Controller {
  static targets = ["read", "edit", "form", "save", "editButton", "cancelButton", "field", "protectedAction"]
  static values = {
    editing: Boolean,
    warningMessage: String,
    previewTitle: String,
    previewIntro: String,
    previewConfirmLabel: String,
    previewBackLabel: String,
    yesLabel: String,
    noLabel: String
  }

  connect() {
    this.allowNativeSubmit = false
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

  startEdit(event) {
    event.preventDefault()
    this.initialValues = this.fieldTargets.map((field) => this.fieldValue(field))
    this.editingValue = true
    this.render()
    this.updateSaveState()
  }

  cancelEdit(event) {
    event.preventDefault()
    this.resetFields()
    this.editingValue = false
    this.render()
  }

  handleInput() {
    this.updateSaveState()
  }

  async handleFormSubmit(event) {
    if (this.allowNativeSubmit) {
      this.allowNativeSubmit = false
      this.applySavingStateToSubmit()
      return
    }

    event.preventDefault()
    event.stopPropagation()

    const summaryHtml = this.buildRecapFromFields()
    const confirmed = await openRichConfirmModal({
      title: this.previewTitleValue,
      introText: this.previewIntroValue,
      htmlBody: summaryHtml,
      confirmText: this.previewConfirmLabelValue,
      cancelText: this.previewBackLabelValue
    })

    if (!confirmed) return

    this.allowNativeSubmit = true
    this.formTarget.requestSubmit()
  }

  applySavingStateToSubmit() {
    if (!this.hasSaveTarget) return
    this.saveTarget.disabled = true
    this.saveTarget.textContent = this.saveTarget.dataset.loadingText || "Enregistrement..."
  }

  render() {
    const editing = this.editingValue

    this.readTargets.forEach((element) => element.classList.toggle("hidden", editing))
    this.editTargets.forEach((element) => element.classList.toggle("hidden", !editing))

    if (this.hasEditButtonTarget) {
      this.editButtonTarget.classList.toggle("hidden", editing)
    }

    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.toggle("hidden", !editing)
    }

    this.protectedActionTargets.forEach((element) => {
      element.classList.toggle("opacity-50", editing)
      element.classList.toggle("pointer-events-none", editing)
      element.setAttribute("aria-disabled", editing ? "true" : "false")
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

  fieldLabelText(field) {
    if (field.labels && field.labels.length > 0) {
      const lab = field.labels[0]
      const span = lab.querySelector(":scope > span")
      if (span) return span.textContent.replace(/\s+/g, " ").trim()

      const clone = lab.cloneNode(true)
      clone.querySelectorAll("input, textarea, select, button").forEach((el) => el.remove())
      return clone.textContent.replace(/\s+/g, " ").trim()
    }
    return field.name || ""
  }

  displayValueForField(field) {
    if (field.type === "checkbox") {
      return field.checked ? this.yesLabelValue : this.noLabelValue
    }
    const v = (field.value || "").trim()
    return v.length ? v : "—"
  }

  buildRecapFromFields() {
    const items = this.fieldTargets.map((field) => {
      const label = this.escapeHtml(this.fieldLabelText(field))
      const value = this.escapeHtml(this.displayValueForField(field))
      return `<li class="flex justify-between gap-3 py-1.5 border-b border-gray-100 last:border-0"><span class="text-gray-600">${label}</span><span class="font-medium text-right">${value}</span></li>`
    })

    if (!items.length) return ""

    return `<ul class="list-none space-y-0">${items.join("")}</ul>`
  }
}
