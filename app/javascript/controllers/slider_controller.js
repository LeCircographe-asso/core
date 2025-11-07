import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper"
import { Navigation, Autoplay } from "swiper/modules"

// Connects to data-controller="slider"
export default class extends Controller {
  static values = {
    options: Object
  }

  connect() {
    this.initialize()
  }

  disconnect() {
    this.destroy()
  }

  initialize() {
    if (this.slider) return

    const defaultOptions = {
      modules: [Navigation, Autoplay],
      loop: true,
      slidesPerView: 1,
      spaceBetween: 16,
      navigation: {
        nextEl: this.element.querySelector(".swiper-button-next"),
        prevEl: this.element.querySelector(".swiper-button-prev")
      },
      breakpoints: {
        768: { slidesPerView: 2 },
        1280: { slidesPerView: 3 }
      }
    }

    const options = Object.assign({}, defaultOptions, this.optionsValue || {})
    this.slider = new Swiper(this.element, options)
  }

  destroy() {
    if (this.slider) {
      this.slider.destroy(true, true)
      this.slider = null
    }
  }
}
