import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number,
    zoom: { type: Number, default: 17 }
  }

  connect () {
    this._disconnected = false
    this._lastSize = { w: 0, h: 0 }
    this._resizeFrame = null

    // Attendre 2 frames : la grille / le turbo-frame ont souvent une hauteur encore à 0 au premier paint.
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (this._disconnected || !this.element.isConnected) return
        this._initMap()
      })
    })
  }

  _initMap () {
    if (this._disconnected || !this.element.isConnected) return

    this._resizeTimeouts = []

    const scheduleInvalidate = (force = false) => {
      if (!this.map) return
      if (this._resizeFrame != null) cancelAnimationFrame(this._resizeFrame)
      this._resizeFrame = requestAnimationFrame(() => {
        this._resizeFrame = null
        const el = this.element
        const w = el.clientWidth
        const h = el.clientHeight
        if (w <= 0 || h <= 0) return
        if (!force && w === this._lastSize.w && h === this._lastSize.h) return
        this._lastSize = { w, h }
        this.map.invalidateSize({ animate: false })
      })
    }

    this.boundTurboFrameLoad = (e) => {
      if (e.target.contains(this.element)) scheduleInvalidate(true)
    }
    document.addEventListener("turbo:frame-load", this.boundTurboFrameLoad)

    this.boundWindowResize = () => scheduleInvalidate(true)
    window.addEventListener("resize", this.boundWindowResize)

    this.map = L.map(this.element).setView([this.latValue, this.lngValue], this.zoomValue)

    // Tuiles raster via CARTO (cartocdn.com) ; rendu 100 % Leaflet côté navigateur (pas d’iframe ni SDK tiers).
    L.tileLayer("https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png", {
      attribution:
        '&copy; <a href="https://wiki.osmfoundation.org/wiki/Licence" rel="nofollow noopener">Sources des données</a> · <a href="https://carto.com/attributions" rel="nofollow noopener">CARTO</a>',
      subdomains: "abcd",
      maxZoom: 19
    }).addTo(this.map)

    // Pas d’images CDN (évite icône cassée si cdnjs / tracking bloqués) — cercle aux couleurs du site.
    L.circleMarker([this.latValue, this.lngValue], {
      radius: 10,
      color: "#1F5C55",
      fillColor: "#5836A5",
      fillOpacity: 0.9,
      weight: 3
    }).addTo(this.map).bindPopup("<strong>Le Circographe</strong><br>97 bis bd de Suisse, Toulouse")

    this.map.whenReady(() => {
      scheduleInvalidate(true)
      ;[120, 350, 700].forEach(ms => {
        const id = setTimeout(() => scheduleInvalidate(true), ms)
        this._resizeTimeouts.push(id)
      })
    })

    this.resizeObserver = new ResizeObserver(() => scheduleInvalidate(false))
    this.resizeObserver.observe(this.element)
  }

  disconnect () {
    this._disconnected = true
    this._resizeTimeouts?.forEach(id => clearTimeout(id))
    this._resizeTimeouts = null
    if (this.boundTurboFrameLoad) {
      document.removeEventListener("turbo:frame-load", this.boundTurboFrameLoad)
      this.boundTurboFrameLoad = null
    }
    if (this.boundWindowResize) {
      window.removeEventListener("resize", this.boundWindowResize)
      this.boundWindowResize = null
    }
    if (this._resizeFrame != null) cancelAnimationFrame(this._resizeFrame)
    this._resizeFrame = null
    this.resizeObserver?.disconnect()
    this.resizeObserver = null
    this.map?.remove()
    this.map = null
  }
}
