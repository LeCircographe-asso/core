import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "dropzone", "fileInput", "loading", "result", "resultContent", "fileName"]

  open() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    this.showDropzone()
    document.addEventListener("keydown", this.handleEscape)
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    document.removeEventListener("keydown", this.handleEscape)
  }

  reset() {
    this.showDropzone()
  }

  handleEscape = (event) => {
    if (event.key === "Escape") this.close()
  }

  handleBackdropClick(event) {
    if (event.target === this.modalTarget) this.close()
  }

  triggerFilePicker() {
    this.fileInputTarget.click()
  }

  onFileSelected() {
    const file = this.fileInputTarget.files[0]
    if (file) this.uploadFile(file)
  }

  dragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-[#1F5C55]", "bg-[#1F5C55]/5")
  }

  dragLeave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-[#1F5C55]", "bg-[#1F5C55]/5")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-[#1F5C55]", "bg-[#1F5C55]/5")

    const file = event.dataTransfer.files[0]
    if (file) this.uploadFile(file)
  }

  async uploadFile(file) {
    this.showLoading(file.name)

    const formData = new FormData()
    formData.append("csv_file", file)

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(this.element.dataset.importModalUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": token, "Accept": "text/html" },
        body: formData
      })

      const html = await response.text()
      this.showResult(html)
    } catch (error) {
      this.showResult(`<div class="px-6 py-8 text-center text-red-600">Erreur réseau : ${error.message}</div>`)
    }
  }

  showDropzone() {
    this.dropzoneTarget.classList.remove("hidden")
    this.loadingTarget.classList.add("hidden")
    this.resultTarget.classList.add("hidden")
    this.fileInputTarget.value = ""
  }

  showLoading(fileName) {
    this.dropzoneTarget.classList.add("hidden")
    this.resultTarget.classList.add("hidden")
    this.loadingTarget.classList.remove("hidden")
    if (this.hasFileNameTarget) this.fileNameTarget.textContent = fileName
  }

  showResult(html) {
    this.dropzoneTarget.classList.add("hidden")
    this.loadingTarget.classList.add("hidden")
    this.resultTarget.classList.remove("hidden")
    this.resultContentTarget.innerHTML = html
  }
}
