import { prefersReducedMotion } from "lib/gsap/animation_prefs"
import { gsap, gsapScoped } from "lib/gsap/register"

document.addEventListener("turbo:load", initAnimations)

function initAnimations () {
  const titleElement = document.getElementById("title")
  const mainButton = document.querySelector(".main-button")
  const mainContent = document.getElementById("main-content")
  const scrollArrow = document.querySelector(".scroll-arrow-container")
  const map = document.querySelector(".map")

  if (!titleElement || !mainButton || !mainContent) {
    return
  }

  const scopeEl = document.querySelector("[data-home-animations-scope]") || mainContent

  const savedTitleText = titleElement.textContent

  gsapScoped(() => {
    if (prefersReducedMotion()) {
      if (titleElement) titleElement.classList.remove("opacity-0")
      if (mainButton) mainButton.classList.remove("opacity-0")
      if (mainContent) mainContent.classList.remove("opacity-0")
      if (map) map.classList.remove("opacity-0")
      if (scrollArrow) scrollArrow.classList.remove("opacity-0")
      return () => {}
    }

    const letters = buildLetterSpans(titleElement)
    if (letters.length) {
      gsap.set(letters, { opacity: 0 })
      gsap.to(letters, {
        opacity: 1,
        duration: 0.15,
        stagger: 0.075,
        ease: "none"
      })
    } else {
      titleElement.classList.remove("opacity-0")
    }

    gsap.fromTo(
      mainButton,
      { opacity: 0 },
      { opacity: 1, duration: 0.5, delay: 1.5, ease: "power2.out",
        onComplete: () => mainButton.classList.remove("opacity-0") }
    )

    if (scrollArrow) {
      gsap.fromTo(
        scrollArrow,
        { opacity: 0 },
        { opacity: 1, duration: 0.5, delay: 1.8, ease: "power2.out",
          onComplete: () => scrollArrow.classList.remove("opacity-0") }
      )
    }

    mainContent.classList.remove("opacity-0")
    if (map) map.classList.remove("opacity-0")

    window.setTimeout(() => {
      document.querySelectorAll(".opacity-0").forEach((el) => el.classList.remove("opacity-0"))
    }, 4000)

    return () => {
      const t = document.getElementById("title")
      if (t && savedTitleText != null) {
        t.textContent = savedTitleText
        t.classList.add("opacity-0")
      }
    }
  }, scopeEl)

  initSmoothScroll()
}

function buildLetterSpans (element) {
  const text = element.textContent
  if (!text) {
    return []
  }

  element.innerHTML = ""
  element.classList.remove("opacity-0")

  const letters = []
  for (let i = 0; i < text.length; i++) {
    const letterSpan = document.createElement("span")
    letterSpan.textContent = text[i] === " " ? " " : text[i]
    letterSpan.style.display = "inline"
    element.appendChild(letterSpan)
    letters.push(letterSpan)
  }
  return letters
}

function initSmoothScroll () {
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener("click", function (e) {
      e.preventDefault()

      const targetId = this.getAttribute("href")
      const targetElement = document.querySelector(targetId)

      if (targetElement) {
        const header = document.querySelector("header")
        const offset = header ? header.offsetHeight + 24 : 0
        const targetPosition = targetElement.getBoundingClientRect().top + window.pageYOffset - offset

        window.scrollTo({
          top: Math.max(targetPosition, 0),
          behavior: "smooth"
        })
      }
    })
  })
}
