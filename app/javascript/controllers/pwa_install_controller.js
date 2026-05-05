import { Controller } from "@hotwired/stimulus"

let deferredInstallPrompt = null

export default class extends Controller {
  static targets = ["container", "button", "status", "iosHelp"]

  connect() {
    this.beforeInstallPromptHandler = this.handleBeforeInstallPrompt.bind(this)
    this.appInstalledHandler = this.handleAppInstalled.bind(this)

    window.addEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.addEventListener("appinstalled", this.appInstalledHandler)

    if (deferredInstallPrompt) {
      this.showPromptReadyState()
    } else if (this.isIosBrowser() && !this.isRunningStandalone()) {
      this.showIosState()
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPromptHandler)
    window.removeEventListener("appinstalled", this.appInstalledHandler)
  }

  async install() {
    if (deferredInstallPrompt) {
      deferredInstallPrompt.prompt()
      const { outcome } = await deferredInstallPrompt.userChoice

      if (outcome === "accepted") {
        this.setStatus("Installation lancée.")
      } else {
        this.setStatus("Installation annulée pour le moment.")
      }

      deferredInstallPrompt = null
      this.hideButton()
      return
    }

    if (this.isIosBrowser() && !this.isRunningStandalone()) {
      this.showIosState(true)
    }
  }

  handleBeforeInstallPrompt(event) {
    event.preventDefault()
    deferredInstallPrompt = event
    this.showPromptReadyState()
  }

  handleAppInstalled() {
    deferredInstallPrompt = null
    this.containerTarget.hidden = false
    this.hideButton()
    this.hideIosHelp()
    this.setStatus("Application installée. Tu peux maintenant la retrouver sur ton écran d'accueil.")
  }

  showPromptReadyState() {
    this.containerTarget.hidden = false
    this.hideIosHelp()
    this.showButton("Installer l'application")
    this.setStatus("Ajoute l'app pour retrouver rapidement les horaires et l'accès.")
  }

  showIosState(expanded = false) {
    this.containerTarget.hidden = false
    this.showButton("Voir comment l'installer")
    this.iosHelpTarget.hidden = !expanded
    this.setStatus("Sur iPhone, l'ajout passe par le menu Partager.")
  }

  showButton(label) {
    this.buttonTarget.hidden = false
    this.buttonTarget.textContent = label
  }

  hideButton() {
    this.buttonTarget.hidden = true
  }

  hideIosHelp() {
    this.iosHelpTarget.hidden = true
  }

  setStatus(message) {
    this.statusTarget.textContent = message
  }

  isRunningStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
  }

  isIosBrowser() {
    const userAgent = window.navigator.userAgent || ""
    return /iPad|iPhone|iPod/.test(userAgent)
  }
}
