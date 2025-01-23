import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "list", "stats" ]

  connect() {
    this.refreshTimer = setInterval(() => {
      this.refreshStats()
    }, 30000) // Rafraîchir toutes les 30 secondes
  }

  disconnect() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  refreshStats() {
    this.statsTarget.requestUpdate()
  }
} 