import { prefersReducedMotion } from "lib/gsap/animation_prefs"
import { gsap, gsapScoped } from "lib/gsap/register"

document.addEventListener("turbo:load", initAnimations)

function initAnimations () {
  const titleElement = document.getElementById("title")
  const heroKicker = document.querySelector(".hero-kicker")
  const heroIntro = document.querySelector(".hero-intro")
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
      if (heroKicker) heroKicker.classList.remove("opacity-0")
      if (titleElement) titleElement.classList.remove("opacity-0")
      if (heroIntro) heroIntro.classList.remove("opacity-0")
      if (mainButton) mainButton.classList.remove("opacity-0")
      if (mainContent) mainContent.classList.remove("opacity-0")
      if (map) map.classList.remove("opacity-0")
      if (scrollArrow) scrollArrow.classList.remove("opacity-0")
      return () => {}
    }

    const letters = buildLetterSpans(titleElement)
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
      titleElement.classList.remove("opacity-0")
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
          onComplete: () => {
            scrollArrow.classList.remove("opacity-0")
            gsap.set([heroKicker, titleElement, heroIntro, mainButton, scrollArrow].filter(Boolean), { clearProps: "transform,will-change" })
          }
        }
      )
    }

    mainContent.classList.remove("opacity-0")
    if (map) map.classList.remove("opacity-0")

    window.setTimeout(() => {
      document.querySelectorAll(".opacity-0").forEach((el) => el.classList.remove("opacity-0"))
    }, 4000)

    return () => {
      if (heroKicker) heroKicker.classList.add("opacity-0")
      const t = document.getElementById("title")
      if (t && savedTitleText != null) {
        t.textContent = savedTitleText
        t.classList.add("opacity-0")
      }
      if (heroIntro) heroIntro.classList.add("opacity-0")
    }
  }, scopeEl)

  initSmoothScroll()
}

function buildLetterSpans (element) {
  const text = element.textContent.trim().replace(/\s+/g, " ")
  if (!text) return []

  element.innerHTML = ""
  element.classList.remove("opacity-0")

  const letters = []
  text.split(" ").forEach((word, wordIndex, arr) => {
    const wordSpan = document.createElement("span")
    wordSpan.className = "home-hero-title-word"

    for (const char of word) {
      const letterSpan = document.createElement("span")
      letterSpan.textContent = char
      letterSpan.style.display = "inline"
      wordSpan.appendChild(letterSpan)
      letters.push(letterSpan)
    }

    element.appendChild(wordSpan)
    if (wordIndex < arr.length - 1) {
      element.appendChild(document.createTextNode(" "))
    }
  })

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
