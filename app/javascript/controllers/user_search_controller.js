import { Controller } from "@hotwired/stimulus"
import { debounce } from "@hotwired/stimulus-loading"

export default class extends Controller {
  static targets = ["input"]

  initialize() {
    this.search = debounce(this.search.bind(this), 300)
  }

  search() {
    const query = this.inputTarget.value
    const form = this.inputTarget.form
    
    if (query.length >= 2 || query.length === 0) {
      requestSubmit(form)
    }
  }
} 