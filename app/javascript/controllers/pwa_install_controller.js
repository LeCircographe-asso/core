import { Controller } from "@hotwired/stimulus"

const DISMISS_KEY = "pwa-install-dismissed-at"
const DISMISS_DAYS = 7

let deferredInstallPrompt = null

export default class extends Controller {
  static targets = ["container", "button", "status", "iosHelp"]

  connect() {
    if (this.isStandalone() || this.isDismissed() || !this.isTouchDevice()) return

    this.beforeInstallPromptHandler = this.handleBeforeInstallPrompt.bind(this)
    this.appInstalledHandler = this.handleAppInstalled.bind(this)
    window.addEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.addEventListener("appinstalled", this.appInstalledHandler)

    if (deferredInstallPrompt) {
      this.revealWhenInView(() => this.showInstallState())
    } else if (this.isIos()) {
      this.revealWhenInView(() => this.showIosState())
    } else {
      // Android/other mobile: show when visible, upgrade to install button if prompt fires in time
      this.revealWhenInView(() => {
        if (deferredInstallPrompt) {
          this.showInstallState()
        } else {
          this.showGenericState()
        }
      })
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.removeEventListener("appinstalled", this.appInstalledHandler)
    this.observer?.disconnect()
  }

  async install() {
    if (deferredInstallPrompt) {
      deferredInstallPrompt.prompt()
      const { outcome } = await deferredInstallPrompt.userChoice
      deferredInstallPrompt = null
      this.hideButton()
      this.setStatus(
        outcome === "accepted"
          ? "Application ajoutée à ton écran d'accueil !"
          : "Tu pourras l'installer plus tard depuis ce menu."
      )
      return
    }

    if (this.isIos()) {
      this.iosHelpTarget.hidden = false
    }
  }

  dismiss() {
    localStorage.setItem(DISMISS_KEY, Date.now().toString())
    this.containerTarget.hidden = true
    this.observer?.disconnect()
  }

  handleBeforeInstallPrompt(event) {
    event.preventDefault()
    deferredInstallPrompt = event
    // If section is already visible, upgrade to install button immediately
    if (!this.containerTarget.hidden) {
      this.showInstallState()
    } else {
      this.revealWhenInView(() => this.showInstallState())
    }
  }

  handleAppInstalled() {
    deferredInstallPrompt = null
    this.containerTarget.hidden = true
    this.observer?.disconnect()
  }

  revealWhenInView(callback) {
    const anchor = this.element.closest("article") || this.element.parentElement
    if (!anchor) { callback(); return }

    this.observer?.disconnect()
    this.observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          this.observer.disconnect()
          setTimeout(callback, 700)
        }
      },
      { threshold: 0.25 }
    )
    this.observer.observe(anchor)
  }

  showInstallState() {
    this.containerTarget.hidden = false
    this.iosHelpTarget.hidden = true
    this.showButton("Installer l'application")
    this.setStatus("Retrouve les horaires et l'accès en un tap depuis ton écran d'accueil.")
  }

  showIosState() {
    this.containerTarget.hidden = false
    this.iosHelpTarget.hidden = true
    this.showButton("Voir comment l'installer")
    this.setStatus("Sur iPhone, l'installation passe par le menu Partager de Safari.")
  }

  showGenericState() {
    this.containerTarget.hidden = false
    this.iosHelpTarget.hidden = true
    this.hideButton()
    this.setStatus("Pour installer : ouvre le menu de ton navigateur et choisis « Ajouter à l'écran d'accueil ».")
  }

  showButton(label) {
    this.buttonTarget.hidden = false
    this.buttonTarget.textContent = label
  }

  hideButton() {
    this.buttonTarget.hidden = true
  }

  setStatus(message) {
    this.statusTarget.textContent = message
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
  }

  isIos() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream
  }

  isTouchDevice() {
    return navigator.maxTouchPoints > 0
  }

  isDismissed() {
    const ts = localStorage.getItem(DISMISS_KEY)
    if (!ts) return false
    return Date.now() - parseInt(ts, 10) < DISMISS_DAYS * 86_400_000
  }
}
