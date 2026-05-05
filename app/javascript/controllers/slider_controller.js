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
      loop: false,
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

    if (options.pagination?.el && typeof options.pagination.el === "string") {
      const paginationEl = this.element.querySelector(options.pagination.el)
      if (paginationEl) {
        options.pagination = { ...options.pagination, el: paginationEl }
      }
    }

    const slideCount = this.element.querySelectorAll(".swiper-slide").length
    const resolvedSlidesPerView = this.resolveSlidesPerView(options.slidesPerView)
    const breakpointValues = Object.values(options.breakpoints || {}).map(cfg => this.resolveSlidesPerView(cfg.slidesPerView))
    const maxSlidesPerView = Math.max(resolvedSlidesPerView, ...breakpointValues, 1)

    if (options.loop && this.shouldDisableLoop(options, slideCount, maxSlidesPerView)) {
      options.loop = false
    }

    if (typeof options.slidesPerView === "number" && slideCount <= maxSlidesPerView) {
      options.slidesPerView = Math.min(options.slidesPerView || 1, slideCount || 1)
      if (options.breakpoints) {
        Object.keys(options.breakpoints).forEach(breakpoint => {
          if (typeof options.breakpoints[breakpoint].slidesPerView === "number") {
            options.breakpoints[breakpoint].slidesPerView = Math.min(options.breakpoints[breakpoint].slidesPerView || 1, slideCount || 1)
          }
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

  resolveSlidesPerView(value) {
    return typeof value === "number" ? value : 1
  }

  shouldDisableLoop(options, slideCount, maxSlidesPerView) {
    if (slideCount <= 1) return true
    if (options.slidesPerView === "auto") {
      return slideCount < 4
    }
    return slideCount <= maxSlidesPerView
  }
}
