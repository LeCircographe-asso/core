import { Controller } from "@hotwired/stimulus"

// Rend une ligne de tableau cliquable pour naviguer vers une URL,
// sans intercepter les clics sur les liens/boutons/contrôles qu'elle contient.
export default class extends Controller {
  static values = { url: String }

  visit(event) {
    if (event.target.closest("a, button, input, select, textarea")) return

    if (event.metaKey || event.ctrlKey || event.shiftKey || event.button === 1) {
      window.open(this.urlValue, "_blank")
      return
    }

    window.location.href = this.urlValue
  }

  keydown(event) {
    if (event.key !== "Enter") return
    if (event.target.closest("a, button, input, select, textarea")) return

    window.location.href = this.urlValue
  }
}
