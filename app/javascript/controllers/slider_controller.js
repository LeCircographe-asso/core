import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper/bundle"

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
    const slideCount = this.element.querySelectorAll(".swiper-slide").length
    const breakpointValues = Object.values(options.breakpoints || {}).map(cfg => cfg.slidesPerView || options.slidesPerView)
    const maxSlidesPerView = Math.max(options.slidesPerView || 1, ...breakpointValues, 1)

    if (slideCount <= maxSlidesPerView) {
      options.loop = false
      options.slidesPerView = Math.min(options.slidesPerView || 1, slideCount || 1)
      if (options.breakpoints) {
        Object.keys(options.breakpoints).forEach(breakpoint => {
          options.breakpoints[breakpoint].slidesPerView = Math.min(options.breakpoints[breakpoint].slidesPerView || 1, slideCount || 1)
        })
      }
    }

    options.allowTouchMove = slideCount > 1

    this.slider = new Swiper(this.element, options)
  }

  destroy() {
    if (this.slider) {
      this.slider.destroy(true, true)
      this.slider = null
    }
  }
}
