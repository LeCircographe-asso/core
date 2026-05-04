import { Controller } from "@hotwired/stimulus"
import { openRichConfirmModal } from "confirm_modal"

// data-controller="section-edit"
export default class extends Controller {
  static targets = ["read", "edit", "form", "save", "modifyWrap", "cancelWrap", "acceptWrap", "modifyButton", "acceptButton", "cancelButton", "field", "protectedAction"]
  static values = {
    editing: Boolean,
    warningMessage: String,
    modifyLabel: String,
    acceptLabel: String,
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

  handleModifyClick(event) {
    event.preventDefault()
    if (this.editingValue) return

    this.initialValues = this.fieldTargets.map((field) => this.fieldValue(field))
    this.editingValue = true
    this.render()
    this.updateSaveState()
  }

  async handleAcceptClick(event) {
    event.preventDefault()
    if (!this.editingValue || !this.hasUnsavedChanges()) return

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

  cancelEdit(event) {
    event.preventDefault()
    this.resetFields()
    this.editingValue = false
    this.render()
  }

  handleInput() {
    this.updateSaveState()
  }

  handleFormSubmit(event) {
    if (this.allowNativeSubmit) {
      this.allowNativeSubmit = false
      this.applySavingStateToSubmit()
      return
    }

    event.preventDefault()
    event.stopPropagation()
  }

  applySavingStateToSubmit() {
    if (this.hasSaveTarget) {
      this.saveTarget.disabled = true
    }

    if (this.hasAcceptWrapTarget && !this.acceptWrapTarget.classList.contains("hidden")) {
      this.acceptButtonTarget.disabled = true
      const loading = this.acceptButtonTarget.dataset.loadingText
      if (loading) this.acceptButtonTarget.textContent = loading
    }
  }

  render() {
    const editing = this.editingValue
    const dirty = this.hasUnsavedChanges()

    this.readTargets.forEach((element) => element.classList.toggle("hidden", editing))
    this.editTargets.forEach((element) => element.classList.toggle("hidden", !editing))

    // Visibility on wrappers only — never combine Tailwind `hidden` with `inline-flex`
    // on the same node (display utilities fight; buttons stayed visible).
    if (this.hasModifyWrapTarget) {
      const showModify = !editing || (editing && !dirty)
      this.modifyWrapTarget.classList.toggle("hidden", !showModify)
    }

    if (this.hasCancelWrapTarget) {
      this.cancelWrapTarget.classList.toggle("hidden", !editing)
    }

    if (this.hasAcceptWrapTarget) {
      this.acceptWrapTarget.classList.toggle("hidden", !(editing && dirty))
    }

    if (this.hasModifyButtonTarget) {
      if (!editing) {
        this.modifyButtonTarget.disabled = false
        this.modifyButtonTarget.textContent = this.modifyLabelValue
      } else if (!dirty) {
        this.modifyButtonTarget.disabled = true
        this.modifyButtonTarget.textContent = this.modifyLabelValue
      } else {
        this.modifyButtonTarget.disabled = false
      }
    }

    if (this.hasAcceptButtonTarget && editing && dirty) {
      this.acceptButtonTarget.disabled = false
      this.acceptButtonTarget.textContent = this.acceptLabelValue
    }

    this.protectedActionTargets.forEach((element) => {
      element.classList.toggle("opacity-50", editing)
      element.classList.toggle("pointer-events-none", editing)
      element.setAttribute("aria-disabled", editing ? "true" : "false")
    })
  }

  updateSaveState() {
    this.render()
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
