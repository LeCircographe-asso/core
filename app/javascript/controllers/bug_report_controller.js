import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "bugReportJsErrors"
const MAX_BUFFER = 20
const MAX_FIELD_LENGTH = 500

function truncate(value) {
  return String(value ?? "").slice(0, MAX_FIELD_LENGTH)
}

function safeStringify(value) {
  if (typeof value === "string") return value
  try {
    return JSON.stringify(value)
  } catch (_e) {
    return String(value)
  }
}

// Installe la capture d'erreurs une seule fois par session navigateur (le flag
// survit aux navigations Turbo — seul un vrai rechargement de page le réinitialise).
// Persisté en sessionStorage : le bug arrive souvent avant que l'utilisateur pense
// à cliquer "Signaler", donc un buffer en mémoire vive perdrait tout entre-temps.
function installErrorCapture() {
  if (window.__bugReportCaptureInstalled) return
  window.__bugReportCaptureInstalled = true

  const push = (entry) => {
    try {
      const buffer = JSON.parse(sessionStorage.getItem(STORAGE_KEY) || "[]")
      const last = buffer[buffer.length - 1]

      if (last && last.type === entry.type && last.message === entry.message && last.line === entry.line) {
        last.count = (last.count || 1) + 1
        last.at_ms = entry.at_ms
      } else {
        buffer.push({ ...entry, count: 1 })
      }

      while (buffer.length > MAX_BUFFER) buffer.shift()
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(buffer))
    } catch (_e) {
      // sessionStorage indisponible (navigation privée stricte) — on abandonne silencieusement.
    }
  }

  window.addEventListener("error", (event) => {
    push({
      type: "error",
      message: truncate(event.message),
      source: event.filename ? event.filename.split("/").pop() : undefined,
      line: event.lineno,
      col: event.colno,
      stack: event.error?.stack ? truncate(event.error.stack) : undefined,
      at_ms: Date.now()
    })
  })

  window.addEventListener("unhandledrejection", (event) => {
    const reason = event.reason
    push({
      type: "unhandledrejection",
      message: truncate(reason?.message ?? safeStringify(reason)),
      stack: reason?.stack ? truncate(reason.stack) : undefined,
      at_ms: Date.now()
    })
  })

  const originalConsoleError = console.error.bind(console)
  console.error = (...args) => {
    push({
      type: "console.error",
      message: truncate(args.map(safeStringify).join(" ")),
      at_ms: Date.now()
    })
    originalConsoleError(...args)
  }
}

function readErrorBuffer() {
  try {
    return JSON.parse(sessionStorage.getItem(STORAGE_KEY) || "[]")
  } catch (_e) {
    return []
  }
}

function detectDeviceType() {
  return window.matchMedia?.("(pointer: coarse)").matches ? "mobile" : "desktop"
}

function detectDisplayMode() {
  const standalone = window.matchMedia?.("(display-mode: standalone)").matches || window.navigator.standalone === true
  return standalone ? "standalone" : "browser"
}

export default class extends Controller {
  static targets = ["panel", "dialog", "trigger"]

  connect() {
    installErrorCapture()
    this.keydownHandler = this.handleKeydown.bind(this)
    this.observePwaBanner()
    this.observeFormSwap()
    this.refreshContextFields()
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydownHandler)
    this.pwaBannerObserver?.disconnect()
    this.formSwapObserver?.disconnect()
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    if (!this.hasPanelTarget) return

    this.previousFocus = document.activeElement
    this.panelTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.keydownHandler)
    this.refreshContextFields()

    requestAnimationFrame(() => {
      if (this.hasDialogTarget) this.dialogTarget.focus()
    })
  }

  close(event) {
    event?.preventDefault()
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.add("hidden")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.keydownHandler)

    if (this.previousFocus && typeof this.previousFocus.focus === "function") {
      this.previousFocus.focus()
    }
    this.previousFocus = null
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close(event)
  }

  // Turbo sérialise le FormData du <form> dès son propre listener "submit" — avant même
  // que "turbo:submit-start" ne soit déclenché — donc injecter les champs à ce moment-là
  // arrive trop tard, ils ne partent jamais dans la requête. On les tient à jour en amont
  // à la place : au rendu initial, à l'ouverture, et à chaque fois que le serveur remplace
  // le <form> (renvoi après erreur), via l'observateur ci-dessous.
  refreshContextFields() {
    const form = document.querySelector("#bug_report_modal_body form")
    if (!form) return

    this.setHiddenField(form, "device_type", detectDeviceType())
    this.setHiddenField(form, "display_mode", detectDisplayMode())
    this.setHiddenField(form, "viewport_width", window.innerWidth)
    this.setHiddenField(form, "viewport_height", window.innerHeight)
    this.setHiddenField(form, "js_errors", JSON.stringify(readErrorBuffer()))
  }

  observeFormSwap() {
    const body = document.getElementById("bug_report_modal_body")
    if (!body) return

    this.formSwapObserver = new MutationObserver(() => this.refreshContextFields())
    this.formSwapObserver.observe(body, { childList: true })
  }

  setHiddenField(form, name, value) {
    let input = form.querySelector(`input[name="${name}"]`)
    if (!input) {
      input = document.createElement("input")
      input.type = "hidden"
      input.name = name
      form.appendChild(input)
    }
    input.value = value
  }

  // Le bouton flottant et la bannière d'installation PWA (shared/_pwa_install_banner)
  // occupent tous les deux le bas de l'écran sur mobile — sans ça, ils se superposent
  // quand la bannière s'affiche. On observe son état plutôt que de coder une hauteur en
  // dur : ni la bannière ni ses variantes (iOS/Android) n'ont une hauteur fixe.
  observePwaBanner() {
    const banner = document.getElementById("pwa-install-banner")
    if (!banner || !this.hasTriggerTarget) return

    const reposition = () => {
      const visible = !banner.hidden && banner.getBoundingClientRect().top < window.innerHeight
      this.triggerTarget.style.bottom = visible ? `${banner.getBoundingClientRect().height + 20}px` : ""
    }

    this.pwaBannerObserver = new MutationObserver(reposition)
    this.pwaBannerObserver.observe(banner, { attributes: true, attributeFilter: [ "hidden", "class" ] })
    banner.addEventListener("transitionend", reposition)
    reposition()
  }
}
