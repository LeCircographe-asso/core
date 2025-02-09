import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  
  connect() {
    this.timeout = null
  }
  
  search() {
    clearTimeout(this.timeout)
    
    this.timeout = setTimeout(() => {
      if (this.inputTarget.value.length >= 2) {
        this.element.requestSubmit()
      }
    }, 300)
  }
} 