import { prefersReducedMotion } from "lib/gsap/animation_prefs"
import { gsap, gsapScoped } from "lib/gsap/register"

document.addEventListener("turbo:load", initAnimations)

function initAnimations () {
  const scopeEl = document.querySelector("[data-home-animations-scope]")
  if (!scopeEl) return
  delete document.body.dataset.homeHeroReady

  const titleElement = scopeEl.querySelector("#title")
  const heroKicker = scopeEl.querySelector(".hero-kicker")
  const heroActions = scopeEl.querySelector(".home-hero-actions")
  const heroPlaceholder = scopeEl.querySelector(".home-hero-placeholder")

  if (!titleElement || !heroActions) {
    return
  }

  const savedTitleText = titleElement.textContent

  gsapScoped(() => {
    if (prefersReducedMotion()) {
      if (savedTitleText != null) titleElement.textContent = savedTitleText
      revealHeroElements([heroKicker, titleElement, heroActions, heroPlaceholder])
      notifyHeroReady()
      return () => {}
    }

    const titleLetters = buildLetterSpans(titleElement)
    const orderedElements = [heroKicker, heroActions, heroPlaceholder].filter(Boolean)
    gsap.set(orderedElements, { autoAlpha: 0, y: 18 })
    gsap.set(titleLetters, { autoAlpha: 0 })

    const timeline = gsap.timeline({
      delay: 0.34,
      defaults: { duration: 0.56, ease: "power2.out" },
      onComplete: () => {
        if (savedTitleText != null) titleElement.textContent = savedTitleText
        revealHeroElements(orderedElements)
        notifyHeroReady()
      }
    })

    timeline
      .to(heroKicker, { autoAlpha: 1, y: 0, duration: 0.42 })
      .to(titleLetters, {
        autoAlpha: 1,
        duration: 0.12,
        stagger: 0.065,
        ease: "none"
      }, "-=0.04")
      .to(heroActions, { autoAlpha: 1, y: 0, duration: 0.46 }, "-=0.14")

    if (heroPlaceholder) {
      timeline.to(heroPlaceholder, { autoAlpha: 1, y: 0, duration: 0.38 }, "-=0.06")
    }

    return () => {
      if (savedTitleText != null) titleElement.textContent = savedTitleText
      revealHeroElements([titleElement])
      ;[heroKicker, heroActions, heroPlaceholder].filter(Boolean).forEach((element) => {
        element.classList.add("opacity-0")
      })
    }
  }, scopeEl)
}

function notifyHeroReady () {
  if (document.body.dataset.homeHeroReady === "true") return
  document.body.dataset.homeHeroReady = "true"
  document.dispatchEvent(new CustomEvent("home:hero-ready"))
}

function revealHeroElements (elements) {
  elements.filter(Boolean).forEach((element) => {
    element.classList.remove("opacity-0")
  })
}

function buildLetterSpans (element) {
  const text = element.textContent
  if (!text) return []

  element.innerHTML = ""
  element.classList.remove("opacity-0")

  const animatedLetters = []

  Array.from(text).forEach((character) => {
    if (character === " ") {
      element.appendChild(document.createTextNode(" "))
      return
    }

    const letterSpan = document.createElement("span")
    letterSpan.textContent = character
    letterSpan.style.display = "inline-block"
    element.appendChild(letterSpan)
    animatedLetters.push(letterSpan)
  })

  return animatedLetters
}
