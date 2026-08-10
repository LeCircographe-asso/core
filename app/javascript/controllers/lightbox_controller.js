import { Controller } from "@hotwired/stimulus"

// Lightbox pour grilles d'images (ex: galerie photo).
// data-controller="lightbox" sur le conteneur ; chaque vignette déclenche
// data-action="lightbox#open" avec data-lightbox-src-param/data-lightbox-alt-param.
export default class extends Controller {
  static targets = ["dialog", "image", "counter"]

  connect() {
    this.items = Array.from(
      this.element.querySelectorAll("[data-lightbox-src-param]")
    ).map((el) => ({
      src: el.dataset.lightboxSrcParam,
      alt: el.dataset.lightboxAltParam || ""
    }))
    this.currentIndex = 0
    this.boundKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    document.body.style.overflow = ""
  }

  open(event) {
    const index = Number(event.params.index)
    if (Number.isNaN(index)) return

    this.currentIndex = index
    this.render()

    this.dialogTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.boundKeydown)
  }

  close() {
    this.dialogTarget.classList.add("hidden")
    document.body.style.overflow = ""
    this.imageTarget.removeAttribute("src")
    document.removeEventListener("keydown", this.boundKeydown)
  }

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.items.length
    this.render()
  }

  prev() {
    this.currentIndex = (this.currentIndex - 1 + this.items.length) % this.items.length
    this.render()
  }

  render() {
    const item = this.items[this.currentIndex]
    if (!item) return

    this.imageTarget.src = item.src
    this.imageTarget.alt = item.alt

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.items.length}`
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    } else if (event.key === "ArrowRight") {
      this.next()
    } else if (event.key === "ArrowLeft") {
      this.prev()
    }
  }
}
