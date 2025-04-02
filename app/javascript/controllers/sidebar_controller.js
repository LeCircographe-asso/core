import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "content", "text"]

  connect() {
    this.checkInitialState()
    this.addResizeListener()
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
  }

  toggle(event) {
    event.preventDefault()
    this.sidebarTarget.classList.toggle('collapsed')
    
    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle('expanded')
    }
    
    if (this.sidebarTarget.classList.contains('collapsed')) {
      this.textTargets.forEach(text => text.classList.add('hidden'))
    } else {
      this.textTargets.forEach(text => text.classList.remove('hidden'))
    }
    
    if (window.innerWidth > 768) {
      localStorage.setItem('sidebarCollapsed', this.sidebarTarget.classList.contains('collapsed'))
    }
  }

  checkInitialState() {
    if (window.innerWidth <= 768 || localStorage.getItem('sidebarCollapsed') === 'true') {
      this.sidebarTarget.classList.add('collapsed')
      if (this.hasContentTarget) {
        this.contentTarget.classList.add('expanded')
      }
      this.textTargets.forEach(text => text.classList.add('hidden'))
    }
  }

  addResizeListener() {
    this.handleResize = this.handleWindowResize.bind(this)
    window.addEventListener('resize', this.handleResize)
  }

  handleWindowResize() {
    if (window.innerWidth <= 768 && !this.sidebarTarget.classList.contains('collapsed')) {
      this.sidebarTarget.classList.add('collapsed')
      if (this.hasContentTarget) {
        this.contentTarget.classList.add('expanded')
      }
      this.textTargets.forEach(text => text.classList.add('hidden'))
    }
  }
}