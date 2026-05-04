let fadeInObserver = null

document.addEventListener("turbo:load", function () {
  if (fadeInObserver) {
    fadeInObserver.disconnect()
    fadeInObserver = null
  }
  initFadeInAnimations()
})

function initFadeInAnimations () {
  const fadeElements = document.querySelectorAll(".fade-in")

  if (fadeElements.length === 0) return

  fadeInObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible")
        observer.unobserve(entry.target)
      }
    })
  }, { threshold: 0.1 })

  fadeElements.forEach(el => fadeInObserver.observe(el))
}
