import { Turbo } from "@hotwired/turbo-rails"

const HIDDEN_CLASS = "hidden"
const DEFAULT_CONFIRM_MESSAGE = "Es-tu sûr·e de vouloir continuer ?"
const DEFAULT_CONFIRM_BODY_FALLBACK = "Êtes-vous sûr de vouloir poursuivre cette action ?"
const DEFAULT_CONFIRM_TITLE = "Confirmation"

let modalElement
let backdropElement
let dialogElement
let messageElement
let titleElement
let confirmButton
let cancelButton
let activeResolve
let previousFocus
let keydownHandler

const DELETE_FORM_SELECTOR = "form"

function cacheElements() {
  modalElement = document.getElementById("confirm-modal")
  if (!modalElement) return false

  backdropElement = document.getElementById("confirm-modal-backdrop")
  dialogElement = modalElement.querySelector("[data-confirm-dialog='true']") || modalElement
  messageElement = document.getElementById("confirm-modal-message")
  titleElement = document.getElementById("confirm-modal-title")
  confirmButton = document.getElementById("confirm-modal-confirm")
  cancelButton = document.getElementById("confirm-modal-cancel")

  return Boolean(messageElement && confirmButton && cancelButton)
}

function resetConfirmModalChrome() {
  if (titleElement) {
    titleElement.textContent = DEFAULT_CONFIRM_TITLE
  }
  if (messageElement) {
    messageElement.replaceChildren()
    const p = document.createElement("p")
    p.className = "text-base leading-relaxed"
    p.textContent = DEFAULT_CONFIRM_BODY_FALLBACK
    messageElement.appendChild(p)
  }
  if (confirmButton) confirmButton.textContent = "Confirmer"
  if (cancelButton) cancelButton.textContent = "Annuler"
}

function closeModal(result) {
  if (!modalElement) return

  modalElement.classList.add(HIDDEN_CLASS)
  modalElement.setAttribute("aria-hidden", "true")

  document.removeEventListener("keydown", keydownHandler)
  keydownHandler = null

  resetConfirmModalChrome()

  if (previousFocus && typeof previousFocus.focus === "function") {
    previousFocus.focus()
  }
  previousFocus = null

  if (activeResolve) {
    activeResolve(result)
    activeResolve = null
  }
}

function showModal(message, element) {
  if (!modalElement && !cacheElements()) {
    // Fallback to native confirm if modal is not found
    return Promise.resolve(window.confirm(message))
  }

  resetConfirmModalChrome()
  messageElement.replaceChildren()
  const p = document.createElement("p")
  p.className = "text-base leading-relaxed"
  p.textContent = message || DEFAULT_CONFIRM_MESSAGE
  messageElement.appendChild(p)

  return new Promise((resolve) => {
    activeResolve = resolve
    previousFocus = document.activeElement

    modalElement.classList.remove(HIDDEN_CLASS)
    modalElement.removeAttribute("aria-hidden")

    requestAnimationFrame(() => {
      if (dialogElement) {
        dialogElement.focus()
      } else {
        confirmButton.focus()
      }
    })

    const finish = (result) => {
      confirmButton.removeEventListener("click", confirmHandler)
      cancelButton.removeEventListener("click", cancelHandler)
      if (backdropElement) {
        backdropElement.removeEventListener("click", backdropHandler)
      }
      closeModal(result)
    }

    const confirmHandler = () => finish(true)
    const cancelHandler = () => finish(false)

    const backdropHandler = (event) => {
      if (event.target === backdropElement) {
        finish(false)
      }
    }

    confirmButton.addEventListener("click", confirmHandler)
    cancelButton.addEventListener("click", cancelHandler)
    if (backdropElement) {
      backdropElement.addEventListener("click", backdropHandler)
    }

    keydownHandler = (event) => {
      if (event.key === "Escape") {
        event.preventDefault()
        finish(false)
      } else if (event.key === "Enter" && document.activeElement === confirmButton) {
        event.preventDefault()
        finish(true)
      }
    }

    document.addEventListener("keydown", keydownHandler)
  })
}

export function openRichConfirmModal(options = {}) {
  const {
    title = DEFAULT_CONFIRM_TITLE,
    introText = "",
    htmlBody = "",
    confirmText = "Confirmer",
    cancelText = "Annuler"
  } = options

  if (!modalElement && !cacheElements()) {
    return Promise.resolve(window.confirm(introText || DEFAULT_CONFIRM_MESSAGE))
  }

  if (titleElement) titleElement.textContent = title
  confirmButton.textContent = confirmText
  cancelButton.textContent = cancelText

  messageElement.replaceChildren()
  if (introText) {
    const intro = document.createElement("p")
    intro.className = "text-base leading-relaxed text-gray-700"
    intro.textContent = introText
    messageElement.appendChild(intro)
  }
  if (htmlBody) {
    const wrap = document.createElement("div")
    wrap.className =
      "mt-2 max-h-52 overflow-y-auto rounded-lg bg-gray-50 px-3 py-2 text-sm text-gray-900 border border-gray-100"
    wrap.innerHTML = htmlBody
    messageElement.appendChild(wrap)
  }

  return new Promise((resolve) => {
    activeResolve = resolve
    previousFocus = document.activeElement

    modalElement.classList.remove(HIDDEN_CLASS)
    modalElement.removeAttribute("aria-hidden")

    requestAnimationFrame(() => {
      if (dialogElement) {
        dialogElement.focus()
      } else {
        confirmButton.focus()
      }
    })

    const finish = (result) => {
      confirmButton.removeEventListener("click", confirmHandler)
      cancelButton.removeEventListener("click", cancelHandler)
      if (backdropElement) {
        backdropElement.removeEventListener("click", backdropHandler)
      }
      closeModal(result)
    }

    const confirmHandler = () => finish(true)
    const cancelHandler = () => finish(false)

    const backdropHandler = (event) => {
      if (event.target === backdropElement) {
        finish(false)
      }
    }

    confirmButton.addEventListener("click", confirmHandler)
    cancelButton.addEventListener("click", cancelHandler)
    if (backdropElement) {
      backdropElement.addEventListener("click", backdropHandler)
    }

    keydownHandler = (event) => {
      if (event.key === "Escape") {
        event.preventDefault()
        finish(false)
      } else if (event.key === "Enter" && document.activeElement === confirmButton) {
        event.preventDefault()
        finish(true)
      }
    }

    document.addEventListener("keydown", keydownHandler)
  })
}

function isDeleteForm(form) {
  if (!(form instanceof HTMLFormElement)) return false
  if (form.dataset.confirmIgnore === "true") return false

  if (form.dataset.turboConfirm) return true

  const method = (form.getAttribute("method") || "").toLowerCase()
  if (method === "delete") return true

  const hiddenMethod = form.querySelector("input[name='_method'][value='delete']")
  if (hiddenMethod) return true

  const submitter = form.querySelector("[data-method='delete']")
  if (submitter) return true

  return false
}

function applyDefaultConfirmMessages(root = document) {
  if (!root) return

  const forms = []

  if (root instanceof HTMLFormElement) {
    forms.push(root)
  } else if (root.querySelectorAll) {
    forms.push(...root.querySelectorAll(DELETE_FORM_SELECTOR))
    if (root.matches && root.matches(DELETE_FORM_SELECTOR)) {
      forms.push(root)
    }
  }

  forms.forEach((form) => {
    if (form.dataset.confirmInitialized === "true") return

    if (isDeleteForm(form)) {
      const submitter = form.querySelector("[data-turbo-confirm]")

      if (!form.dataset.turboConfirm && submitter?.dataset.turboConfirm) {
        form.dataset.turboConfirm = submitter.dataset.turboConfirm
      }

      if (!form.dataset.turboConfirm) {
        form.dataset.turboConfirm = DEFAULT_CONFIRM_MESSAGE
      }
    }

    form.dataset.confirmInitialized = "true"
  })
}

document.addEventListener("turbo:load", () => {
  cacheElements()
  applyDefaultConfirmMessages()

  if (!window.__confirmModalObserver) {
    window.__confirmModalObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType !== Node.ELEMENT_NODE) return

          if (node.matches && node.matches(DELETE_FORM_SELECTOR)) {
            delete node.dataset.confirmInitialized
            applyDefaultConfirmMessages(node)
          } else if (node.querySelectorAll) {
            applyDefaultConfirmMessages(node)
          }
        })
      })
    })

    window.__confirmModalObserver.observe(document.body, {
      childList: true,
      subtree: true
    })
  }
})

Turbo.setConfirmMethod((message, element) => {
  return showModal(message, element)
})


