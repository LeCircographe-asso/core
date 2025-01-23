import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  redirect(event) {
    event.preventDefault()
    const query = this.inputTarget.value
    
    if (query.length > 0) {
      window.location.href = `/admin/users?query=${encodeURIComponent(query)}`
    }
  }
} 