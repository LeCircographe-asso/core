import { Controller } from "@hotwired/stimulus"
import { gsap } from "lib/gsap/register"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

// Connects to data-controller="graffiti-cursor"
export default class extends Controller {
  static targets = ["board", "layer", "cursor", "halo", "slider", "value"]

  static values = {
    halo: Number,
    trailFade: Number,
    trailInterval: Number,
    trailDistance: Number,
    maxTransient: Number,
    maxPersistent: Number
  }

  connect () {
    this._bounds = null
    this._lastStampAt = 0
    this._lastStampPoint = null
    this._transientNodes = []
    this._persistentNodes = []
    this._cursorVisible = false
    this._reducedMotion = prefersReducedMotion()
    this._finePointer = typeof window !== "undefined" &&
      window.matchMedia("(pointer: fine)").matches

    this._refreshBounds = this._refreshBounds.bind(this)

    window.addEventListener("resize", this._refreshBounds, { passive: true })
    window.addEventListener("scroll", this._refreshBounds, { passive: true })

    this._applyHalo(this.currentHalo)
    this._syncValue()
    this._refreshBounds()
    this._setupCursorMotion()

    if (!this._finePointer) {
      this.cursorTarget.hidden = true
    } else {
      gsap.set(this.cursorTarget, { xPercent: -50, yPercent: -50, opacity: 0, scale: 0.94 })
      gsap.set(this.haloTarget, { scale: 1 })
    }
  }

  disconnect () {
    window.removeEventListener("resize", this._refreshBounds)
    window.removeEventListener("scroll", this._refreshBounds)
    gsap.killTweensOf([this.cursorTarget, this.haloTarget])
  }

  showCursor (event) {
    if (!this._finePointer) return

    this.cursorTarget.classList.add("white-page-cursor--visible")
    if (!this._cursorVisible) {
      this._cursorVisible = true
      gsap.to(this.cursorTarget, {
        opacity: 1,
        scale: 1,
        duration: 0.18,
        ease: "power2.out",
        overwrite: true
      })
    }
    this._snapCursor(event.clientX, event.clientY)
  }

  hideCursor () {
    this.cursorTarget.classList.remove("white-page-cursor--visible")
    this._cursorVisible = false
    gsap.to(this.cursorTarget, {
      opacity: 0,
      scale: 0.94,
      duration: 0.14,
      ease: "power2.out",
      overwrite: true
    })
  }

  track (event) {
    const point = this._localPoint(event)
    if (!point) return

    if (this._finePointer) this._moveCursor(event.clientX, event.clientY)

    if (this._reducedMotion || event.pointerType === "touch") return
    if (!this._shouldSpawnTransient(point)) return

    this._lastStampAt = performance.now()
    this._lastStampPoint = point

    this._spawnStamp(point, { persistent: false })
  }

  persist (event) {
    const point = this._localPoint(event)
    if (!point) return

    this._snapCursor(event.clientX, event.clientY)
    this._spawnStamp(point, { persistent: true })
  }

  plantFromKeyboard (event) {
    event.preventDefault()

    this._refreshBounds()
    const x = this._bounds.width / 2
    const y = this._bounds.height / 2

    this._spawnStamp({ x, y }, { persistent: true })
  }

  adjustHalo (event) {
    this.haloValue = Number(event.currentTarget.value)
    this._applyHalo(this.currentHalo)
    this._syncValue()
  }

  clearPersistent () {
    this._persistentNodes.forEach((node) => {
      gsap.killTweensOf(node)
      node.remove()
    })
    this._persistentNodes = []
  }

  get currentHalo () {
    return this.hasHaloValue ? this.haloValue : 120
  }

  _refreshBounds () {
    this._bounds = this.boardTarget.getBoundingClientRect()
  }

  _syncValue () {
    if (this.hasValueTarget) this.valueTarget.textContent = `${this.currentHalo} px`
    if (this.hasSliderTarget) this.sliderTarget.value = this.currentHalo
  }

  _applyHalo (size) {
    this.boardTarget.style.setProperty("--graffiti-halo-size", `${size}px`)
    if (this.hasHaloTarget) {
      gsap.to(this.haloTarget, {
        width: size,
        height: size,
        duration: 0.2,
        ease: "power2.out",
        overwrite: true
      })
    }
  }

  _moveCursor (clientX, clientY) {
    if (this._cursorXSet && this._cursorYSet) {
      this._cursorXSet(clientX)
      this._cursorYSet(clientY)
    } else {
      gsap.set(this.cursorTarget, { x: clientX, y: clientY })
    }
  }

  _snapCursor (clientX, clientY) {
    gsap.killTweensOf(this.cursorTarget)
    this._moveCursor(clientX, clientY)

    gsap.set(this.cursorTarget, {
      opacity: this._cursorVisible ? 1 : 0,
      scale: 1
    })
  }

  _localPoint (event) {
    if (!this._bounds) this._refreshBounds()

    const { left, top, right, bottom } = this._bounds
    const { clientX, clientY } = event

    if (clientX < left || clientX > right || clientY < top || clientY > bottom) return null

    return {
      x: clientX - left,
      y: clientY - top
    }
  }

  _shouldSpawnTransient (point) {
    const now = performance.now()
    const interval = this.hasTrailIntervalValue ? this.trailIntervalValue : 34
    const minDistance = this.hasTrailDistanceValue ? this.trailDistanceValue : 18

    if ((now - this._lastStampAt) < interval) return false
    if (!this._lastStampPoint) return true

    const deltaX = point.x - this._lastStampPoint.x
    const deltaY = point.y - this._lastStampPoint.y

    return Math.hypot(deltaX, deltaY) >= minDistance
  }

  _spawnStamp (point, { persistent }) {
    const stamp = document.createElement("div")
    const lifetime = Math.max((this.hasTrailFadeValue ? this.trailFadeValue : 0.22), 0.12)
    const size = persistent ? this._randomBetween(42, 96) : this._randomBetween(16, 34)
    const rotation = this._randomBetween(-18, 18)
    const opacity = persistent ? this._randomBetween(0.52, 0.78) : this._randomBetween(0.18, 0.34)

    stamp.className = persistent ? "white-page-spray white-page-spray--persistent" : "white-page-spray white-page-spray--transient"
    stamp.style.left = `${point.x}px`
    stamp.style.top = `${point.y}px`
    stamp.style.width = `${size}px`
    stamp.style.height = `${size}px`
    stamp.style.color = this._pickColor()
    stamp.innerHTML = this._buildSpraySvg(persistent)

    this.layerTarget.appendChild(stamp)

    if (persistent) {
      this._persistentNodes.push(stamp)
      this._trimNodes(this._persistentNodes, this.hasMaxPersistentValue ? this.maxPersistentValue : 80)
    } else {
      this._transientNodes.push(stamp)
      this._trimNodes(this._transientNodes, this.hasMaxTransientValue ? this.maxTransientValue : 24)
    }

    this._animateStamp(stamp, { persistent, rotation, opacity, lifetime })
    this._pulseHalo(persistent)
  }

  _trimNodes (nodes, max) {
    while (nodes.length > max) {
      const oldest = nodes.shift()
      if (oldest) {
        gsap.killTweensOf(oldest)
        oldest.remove()
      }
    }
  }

  _buildSpraySvg (persistent) {
    const haze = Array.from({ length: persistent ? 5 : 3 }, () => {
      const angle = this._randomBetween(0, Math.PI * 2)
      const distance = this._randomBetween(4, persistent ? 18 : 10)
      const rx = this._randomBetween(5, persistent ? 12 : 8)
      const ry = this._randomBetween(2.5, persistent ? 5.5 : 4)
      const cx = 50 + Math.cos(angle) * distance
      const cy = 50 + Math.sin(angle) * distance
      const rotate = this._randomBetween(-35, 35)

      return `<ellipse cx="${cx.toFixed(2)}" cy="${cy.toFixed(2)}" rx="${rx.toFixed(2)}" ry="${ry.toFixed(2)}" opacity="${persistent ? "0.20" : "0.14"}" transform="rotate(${rotate.toFixed(2)} ${cx.toFixed(2)} ${cy.toFixed(2)})" />`
    }).join("")

    const droplets = Array.from({ length: persistent ? 18 : 10 }, () => {
      const angle = this._randomBetween(0, Math.PI * 2)
      const distance = this._randomBetween(8, persistent ? 34 : 24)
      const radius = this._randomBetween(0.7, persistent ? 3.2 : 1.8)
      const cx = 50 + Math.cos(angle) * distance
      const cy = 50 + Math.sin(angle) * distance

      return `<circle cx="${cx.toFixed(2)}" cy="${cy.toFixed(2)}" r="${radius.toFixed(2)}" opacity="${this._randomBetween(0.35, persistent ? 0.88 : 0.62).toFixed(2)}" />`
    }).join("")

    const streaks = Array.from({ length: persistent ? 4 : 2 }, () => {
      const x1 = this._randomBetween(38, 62)
      const y1 = this._randomBetween(38, 62)
      const x2 = x1 + this._randomBetween(-10, 10)
      const y2 = y1 + this._randomBetween(-18, 18)

      return `<line x1="${x1.toFixed(2)}" y1="${y1.toFixed(2)}" x2="${x2.toFixed(2)}" y2="${y2.toFixed(2)}" stroke="currentColor" stroke-linecap="round" stroke-width="${persistent ? "1.5" : "1"}" opacity="${persistent ? "0.28" : "0.18"}" />`
    }).join("")

    return `
      <svg viewBox="0 0 100 100" fill="currentColor" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
        ${haze}
        ${droplets}
        ${streaks}
      </svg>
    `
  }

  _animateStamp (stamp, { persistent, rotation, opacity, lifetime }) {
    if (this._reducedMotion) {
      gsap.set(stamp, {
        xPercent: -50,
        yPercent: -50,
        rotate: rotation,
        scale: 1,
        opacity: persistent ? Math.max(opacity, 0.46) : 0.12
      })
      if (!persistent) {
        stamp.remove()
        this._transientNodes = this._transientNodes.filter((node) => node !== stamp)
      }
      return
    }

    gsap.set(stamp, {
      xPercent: -50,
      yPercent: -50,
      rotate: rotation,
      scale: persistent ? 0.78 : 0.72,
      opacity: 0,
      filter: "blur(1.8px)"
    })

    if (persistent) {
      gsap.to(stamp, {
        scale: 1,
        opacity,
        filter: "blur(0px)",
        duration: 0.28,
        ease: "power2.out",
        overwrite: true
      })
      return
    }

    gsap.to(stamp, {
      scale: 1.1,
      opacity: 0,
      filter: "blur(3px)",
      duration: lifetime,
      ease: "power1.out",
      overwrite: true,
      onStart: () => gsap.set(stamp, { opacity }),
      onComplete: () => {
        stamp.remove()
        this._transientNodes = this._transientNodes.filter((node) => node !== stamp)
      }
    })
  }

  _pulseHalo (persistent) {
    if (!this._finePointer || !this.hasHaloTarget || this._reducedMotion) return

    gsap.fromTo(this.haloTarget,
      { scale: persistent ? 1.02 : 1 },
      {
        scale: 1,
        duration: persistent ? 0.34 : 0.22,
        ease: "power2.out",
        overwrite: true
      }
    )
  }

  _setupCursorMotion () {
    if (!this._finePointer) return

    this._cursorXSet = gsap.quickSetter(this.cursorTarget, "x", "px")
    this._cursorYSet = gsap.quickSetter(this.cursorTarget, "y", "px")
  }

  _pickColor () {
    const palette = [
      "rgba(88, 54, 165, 0.92)",
      "rgba(72, 38, 145, 0.88)",
      "rgba(109, 74, 194, 0.84)",
      "rgba(95, 53, 181, 0.9)"
    ]

    return palette[Math.floor(Math.random() * palette.length)]
  }

  _randomBetween (min, max) {
    return min + Math.random() * (max - min)
  }
}
