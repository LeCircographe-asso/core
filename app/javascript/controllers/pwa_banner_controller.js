import { Controller } from "@hotwired/stimulus"

const DISMISS_KEY = "pwa-install-dismissed-at"
const DISMISS_DAYS = 7
const IOS_DELAY_MS = 3500

let deferredPrompt = null

export default class extends Controller {
  static targets = ["installBtn", "iosHint", "iosInstructions"]

  connect() {
    if (this.isStandalone() || this.isDismissed() || !this.isTouchDevice()) return

    this.onBeforeInstall = (event) => {
      event.preventDefault()
      deferredPrompt = event
      this.showBanner("android")
    }
    this.onAppInstalled = () => {
      deferredPrompt = null
      this.hideBanner()
    }

    window.addEventListener("beforeinstallprompt", this.onBeforeInstall)
    window.addEventListener("appinstalled", this.onAppInstalled)

    // iOS has no beforeinstallprompt — show after a short delay, once per session
    if (this.isIos() && !sessionStorage.getItem("pwa-banner-ios-shown")) {
      sessionStorage.setItem("pwa-banner-ios-shown", "1")
      this.iosTimer = setTimeout(() => this.showBanner("ios"), IOS_DELAY_MS)
    }
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.onBeforeInstall)
    window.removeEventListener("appinstalled", this.onAppInstalled)
    clearTimeout(this.iosTimer)
  }

  async install() {
    if (!deferredPrompt) return
    deferredPrompt.prompt()
    const { outcome } = await deferredPrompt.userChoice
    deferredPrompt = null
    if (outcome === "accepted") {
      this.hideBanner()
    } else {
      this.installBtnTarget.textContent = "Installer plus tard"
      setTimeout(() => this.hideBanner(), 2000)
    }
  }

  dismiss() {
    localStorage.setItem(DISMISS_KEY, Date.now().toString())
    this.hideBanner()
  }

  toggleIosInstructions() {
    const panel = this.iosInstructionsTarget
    panel.hidden = !panel.hidden
  }

  showBanner(type) {
    this.installBtnTarget.hidden = type !== "android"
    this.iosHintTarget.hidden = type !== "ios"

    this.element.hidden = false
    // Double rAF ensures the initial translate-y-full is painted before we remove it
    requestAnimationFrame(() =>
      requestAnimationFrame(() => {
        this.element.classList.remove("translate-y-full")
        this.element.classList.add("translate-y-0")
      })
    )
  }

  hideBanner() {
    this.element.classList.remove("translate-y-0")
    this.element.classList.add("translate-y-full")
    setTimeout(() => { this.element.hidden = true }, 320)
  }

  isStandalone() {
    return (
      window.matchMedia("(display-mode: standalone)").matches ||
      navigator.standalone === true
    )
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
