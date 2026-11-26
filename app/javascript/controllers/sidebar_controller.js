import { Controller } from "@hotwired/stimulus"

// Same breakpoint as the @media block of admin_sidebar.css.
const MOBILE_MAX_WIDTH = 768

export default class extends Controller {
  static targets = ["sidebar", "content", "text", "backdrop", "mobileToggle"]
  static outlets = ["submenu"]

  connect() {
    this.isAnimating = false
    this.checkInitialState()
    this.addResizeListener()
    this.handleKeydown = (event) => { if (event.key === "Escape") this.closeMobile() }
    // On a phone, choosing a link closes the drawer (Turbo then renders the new page).
    this.handleSidebarClick = (event) => { if (this.isMobile() && event.target.closest("a")) this.closeMobile() }
    this.sidebarTarget.addEventListener("click", this.handleSidebarClick)
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
    document.removeEventListener("keydown", this.handleKeydown)
    this.sidebarTarget.removeEventListener("click", this.handleSidebarClick)
  }

  isMobile() {
    return window.innerWidth <= MOBILE_MAX_WIDTH
  }

  // Mobile drawer: full sidebar (with labels) over the page, behind a backdrop.
  openMobile(event) {
    event?.preventDefault()
    this.sidebarTarget.classList.remove("collapsed")
    this.sidebarTarget.classList.add("mobile-open")
    this.textTargets.forEach(text => text.classList.remove("hidden"))
    if (this.hasBackdropTarget) this.backdropTarget.hidden = false
    if (this.hasMobileToggleTarget) this.mobileToggleTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("keydown", this.handleKeydown)
    this.sidebarTarget.querySelector("a, button")?.focus()
  }

  closeMobile(event) {
    event?.preventDefault()
    if (!this.sidebarTarget.classList.contains("mobile-open")) return
    this.sidebarTarget.classList.remove("mobile-open")
    this.sidebarTarget.classList.add("collapsed")
    this.textTargets.forEach(text => text.classList.add("hidden"))
    if (this.hasBackdropTarget) this.backdropTarget.hidden = true
    if (this.hasMobileToggleTarget) {
      this.mobileToggleTarget.setAttribute("aria-expanded", "false")
      this.mobileToggleTarget.focus()
    }
    document.removeEventListener("keydown", this.handleKeydown)
  }

  toggle(event) {
    event.preventDefault()
    // On a phone the "Menu" button inside the drawer closes it.
    if (this.isMobile()) return this.closeMobile()
    if (this.isAnimating) return

    this.isAnimating = true
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

    setTimeout(() => { this.isAnimating = false }, 350)
  }

  toggleSubmenu(event) {
    event.preventDefault()
    const button = event.currentTarget
    const submenu = button.nextElementSibling
    const chevron = button.querySelector('.submenu-chevron')

    if (!submenu) return

    submenu.classList.toggle('hidden')
    if (chevron) {
      chevron.classList.toggle('rotate-90')
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
    if (!this.isMobile() && this.sidebarTarget.classList.contains("mobile-open")) {
      this.closeMobile()
    }
    if (this.isMobile() && !this.sidebarTarget.classList.contains('collapsed') && !this.sidebarTarget.classList.contains("mobile-open")) {
      this.sidebarTarget.classList.add('collapsed')
      if (this.hasContentTarget) {
        this.contentTarget.classList.add('expanded')
      }
      this.textTargets.forEach(text => text.classList.add('hidden'))
    }
  }
}