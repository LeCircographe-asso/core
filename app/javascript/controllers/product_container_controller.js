import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.element.addEventListener("turbo:submit-end", this.handleSubmit)
    }

    disconnect() {
        this.element.removeEventListener("turbo:submit-end", this.handleSubmit)
    }

    handleSubmit = (event) => {
        if (event.detail.success) {
        Turbo.visit(window.location.href, { action: "replace" })
        }
    }
}
