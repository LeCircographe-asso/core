const MODAL_ID    = "whatsapp-qr-modal"
const BACKDROP_ID = "whatsapp-qr-backdrop"
const DIALOG_ID   = "whatsapp-qr-dialog"
const CLOSE_ID    = "whatsapp-qr-close"
const TRIGGER_SEL = "[data-whatsapp-qr]"

let modalEl, backdropEl, dialogEl
let previousFocus = null
let keydownHandler = null

function cacheElements() {
  modalEl    = document.getElementById(MODAL_ID)
  backdropEl = document.getElementById(BACKDROP_ID)
  dialogEl   = document.getElementById(DIALOG_ID)
  return Boolean(modalEl)
}

function openModal(event) {
  if (event) event.preventDefault()
  if (!modalEl && !cacheElements()) return

  previousFocus = document.activeElement
  modalEl.classList.remove("hidden")

  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      backdropEl.classList.remove("opacity-0")
      backdropEl.classList.add("opacity-100")
      dialogEl.classList.remove("opacity-0", "scale-95", "translate-y-2")
      dialogEl.classList.add("opacity-100", "scale-100", "translate-y-0")
      dialogEl.focus()
    })
  })

  keydownHandler = (e) => { if (e.key === "Escape") { e.preventDefault(); closeModal() } }
  document.addEventListener("keydown", keydownHandler)
}

function closeModal() {
  if (!modalEl) return

  backdropEl.classList.remove("opacity-100")
  backdropEl.classList.add("opacity-0")
  dialogEl.classList.remove("opacity-100", "scale-100", "translate-y-0")
  dialogEl.classList.add("opacity-0", "scale-95", "translate-y-2")

  document.removeEventListener("keydown", keydownHandler)
  keydownHandler = null

  setTimeout(() => {
    modalEl.classList.add("hidden")
    previousFocus?.focus()
    previousFocus = null
  }, 200)
}

function init() {
  if (!cacheElements()) return

  document.getElementById(CLOSE_ID)?.addEventListener("click", closeModal)
  backdropEl?.addEventListener("click", (e) => { if (e.target === backdropEl) closeModal() })

  document.querySelectorAll(TRIGGER_SEL).forEach((el) => {
    el.addEventListener("click", openModal)
  })
}

document.addEventListener("turbo:load", init)
