import { Controller } from "@hotwired/stimulus"

// data-controller="section-edit"
export default class extends Controller {
  static targets = ["read", "edit", "save", "editButton", "cancelButton", "field", "protectedAction"]
  static values = { editing: Boolean, warningMessage: String }

  connect() {
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

  beforeSubmit() {
    if (!this.hasSaveTarget) return
    this.saveTarget.disabled = true
    this.saveTarget.textContent = this.saveTarget.dataset.loadingText || "Enregistrement..."
  }

  render() {
    const editing = this.editingValue

    this.readTargets.forEach((element) => element.classList.toggle("hidden", editing))
    this.editTargets.forEach((element) => element.classList.toggle("hidden", !editing))

    if (this.hasEditButtonTarget) this.editButtonTarget.classList.toggle("hidden", editing)
    if (this.hasCancelButtonTarget) this.cancelButtonTarget.classList.toggle("hidden", !editing)
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
}
