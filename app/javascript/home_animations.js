import { prefersReducedMotion } from "lib/gsap/animation_prefs"
import { gsap, gsapScoped } from "lib/gsap/register"

document.addEventListener("turbo:load", initAnimations)

function initAnimations () {
  const scopeEl = document.querySelector("[data-home-animations-scope]")
  if (!scopeEl) return

  const titleElement = scopeEl.querySelector("#title")
  const heroKicker = scopeEl.querySelector(".hero-kicker")
  const heroIntro = scopeEl.querySelector(".hero-intro")
  const mainButton = scopeEl.querySelector(".main-button")
  const mainContent = scopeEl.querySelector("#main-content")
  const scrollArrow = scopeEl.querySelector(".scroll-arrow-container")
  const map = scopeEl.querySelector(".map")

  if (!titleElement || !mainButton || !mainContent) {
    return
  }

  const savedTitleText = titleElement.textContent
  const shouldSplitLetters = !window.matchMedia("(max-width: 639px)").matches
  let opacityCleanupTimer = null

  gsapScoped(() => {
    if (prefersReducedMotion()) {
      if (heroKicker) heroKicker.classList.remove("opacity-0")
      if (titleElement) titleElement.classList.remove("opacity-0")
      if (heroIntro) heroIntro.classList.remove("opacity-0")
      if (mainButton) mainButton.classList.remove("opacity-0")
      if (mainContent) mainContent.classList.remove("opacity-0")
      if (map) map.classList.remove("opacity-0")
      if (scrollArrow) scrollArrow.classList.remove("opacity-0")
      return () => {}
    }

    const letters = shouldSplitLetters ? buildLetterSpans(titleElement) : []
    if (heroKicker) {
      gsap.fromTo(
        heroKicker,
        { opacity: 0, y: -14 },
        { opacity: 1, y: 0, duration: 0.45, ease: "power2.out",
          onComplete: () => heroKicker.classList.remove("opacity-0") }
      )
    }

    if (letters.length) {
      gsap.set(letters, { opacity: 0 })
      gsap.to(letters, {
        opacity: 1,
        duration: 0.15,
        stagger: 0.075,
        ease: "none"
      })
    } else {
      gsap.fromTo(
        titleElement,
        { opacity: 0, y: 10 },
        { opacity: 1, y: 0, duration: 0.45, delay: 0.08, ease: "power2.out",
          onComplete: () => titleElement.classList.remove("opacity-0") }
      )
    }

    if (heroIntro) {
      gsap.fromTo(
        heroIntro,
        { opacity: 0, y: 18 },
        { opacity: 1, y: 0, duration: 0.55, delay: 0.45, ease: "power2.out",
          onComplete: () => heroIntro.classList.remove("opacity-0") }
      )
    }

    gsap.fromTo(
      mainButton,
      { opacity: 0, y: 16 },
      { opacity: 1, y: 0, duration: 0.5, delay: 1.1, ease: "power2.out",
        onComplete: () => mainButton.classList.remove("opacity-0") }
    )

    if (scrollArrow) {
      gsap.fromTo(
        scrollArrow,
        { opacity: 0, y: 10 },
        { opacity: 1, y: 0, duration: 0.5, delay: 1.35, ease: "power2.out",
          onComplete: () => scrollArrow.classList.remove("opacity-0") }
      )
    }

    mainContent.classList.remove("opacity-0")
    if (map) map.classList.remove("opacity-0")

    opacityCleanupTimer = window.setTimeout(() => {
      scopeEl.querySelectorAll(".opacity-0").forEach((el) => el.classList.remove("opacity-0"))
    }, 4000)

    return () => {
      if (opacityCleanupTimer) {
        window.clearTimeout(opacityCleanupTimer)
        opacityCleanupTimer = null
      }
      if (heroKicker) heroKicker.classList.add("opacity-0")
      const t = scopeEl.querySelector("#title")
      if (t && savedTitleText != null) {
        t.textContent = savedTitleText
        t.classList.add("opacity-0")
      }
      if (heroIntro) heroIntro.classList.add("opacity-0")
    }
  }, scopeEl)

  initSmoothScroll(scopeEl)
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

function initSmoothScroll (scopeEl) {
  scopeEl.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    if ((anchor.dataset.action || "").includes("scroll-hint#scrollToSection")) return
    if (anchor.dataset.homeSmoothScrollBound === "true") return
    anchor.dataset.homeSmoothScrollBound = "true"

    anchor.addEventListener("click", function (e) {
      e.preventDefault()

      const targetId = this.getAttribute("href")
      if (!targetId || targetId === "#") return
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
