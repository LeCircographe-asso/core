import { Controller } from "@hotwired/stimulus"

// FAQ page (app/views/pages/faq.html.erb): instant search over questions and answers,
// opening the question named by the URL anchor (/faq#horaires), and keeping the category
// shortcuts just below the sticky navbar. Without JS the page still works: every question
// is a native <details>, every shortcut a plain anchor.
export default class extends Controller {
  static targets = ["input", "item", "group", "chip", "empty", "status", "chips"]

  connect () {
    this.#syncStickyTop()
    this.onResize = () => this.#syncStickyTop()
    window.addEventListener("resize", this.onResize)
    this.onHashChange = () => this.#openFromHash()
    window.addEventListener("hashchange", this.onHashChange)
    this.#openFromHash()
    this.#observeGroups()
  }

  disconnect () {
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("hashchange", this.onHashChange)
    this.observer?.disconnect()
  }

  // Shortcut click: highlight it right away (the observer follows while scrolling).
  activate (event) {
    const li = event.currentTarget.closest("[data-group]")
    if (li) this.#setActive(li.dataset.group)
  }

  filter () {
    const query = this.#normalize(this.inputTarget.value.trim())
    let shown = 0

    this.itemTargets.forEach((item) => {
      if (item.dataset.searchText === undefined) item.dataset.searchText = this.#normalize(item.textContent)
      const match = query === "" || item.dataset.searchText.includes(query)
      item.hidden = !match
      if (match) shown++
      // Open matches only for a real query, so the answer is visible right away.
      if (query.length >= 3) item.open = match
      else if (query === "") item.open = false
    })

    this.groupTargets.forEach((group) => {
      const visible = this.itemTargets.some(item => group.contains(item) && !item.hidden)
      group.hidden = !visible
      const chip = this.chipTargets.find(c => c.dataset.group === group.id)
      if (chip) chip.hidden = !visible
    })

    this.emptyTarget.classList.toggle("hidden", shown > 0)
    this.statusTarget.textContent = query === "" ? "" : `${shown} question${shown > 1 ? "s" : ""} trouvée${shown > 1 ? "s" : ""}`
  }

  clear () {
    this.inputTarget.value = ""
    this.filter()
  }

  #openFromHash () {
    const id = decodeURIComponent(window.location.hash.slice(1))
    if (!id) return
    const item = this.itemTargets.find(i => i.id === id)
    if (!item) return
    if (this.inputTarget.value !== "") this.clear()
    item.open = true
    item.scrollIntoView({ block: "start" })
  }

  // The shortcut of the group being read takes the site's active tab style (.faq-tab[data-active]:
  // violet, the others green outline), as the former FAQ tabs did.
  #observeGroups () {
    if (!("IntersectionObserver" in window)) return
    this.inView = new Map()
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => this.inView.set(entry.target.id, entry.isIntersecting))
      const current = this.groupTargets.find(group => !group.hidden && this.inView.get(group.id))
      if (current) this.#setActive(current.id)
    }, { rootMargin: "-30% 0px -55% 0px" })
    this.groupTargets.forEach(group => this.observer.observe(group))
  }

  #setActive (groupId) {
    this.chipTargets.forEach((li) => {
      const link = li.querySelector("a")
      const active = li.dataset.group === groupId
      link.toggleAttribute("data-active", active)
      if (active) {
        link.setAttribute("aria-current", "true")
        // Keep the active shortcut visible in the horizontally scrolling row (phones).
        const row = li.parentElement
        row.scrollTo({ left: li.offsetLeft - row.offsetLeft - 16, behavior: "smooth" })
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }

  // Stack the shortcuts under the navbar only if the navbar really sticks: it is declared
  // sticky but wrapped in an inline <turbo-frame> no taller than itself, so today it
  // scrolls away and the shortcuts go to the very top. CSSOM, not a style attribute (CSP).
  #syncStickyTop () {
    const nav = document.querySelector("nav.sticky")
    const sticks = nav && nav.parentElement.getBoundingClientRect().height > nav.getBoundingClientRect().height + 1
    this.element.style.setProperty("--faq-sticky-top", sticks ? `${Math.round(nav.getBoundingClientRect().height)}px` : "0px")
  }

  #normalize (text) {
    return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
  }
}
