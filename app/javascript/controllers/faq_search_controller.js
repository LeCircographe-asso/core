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
  }

  disconnect () {
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("hashchange", this.onHashChange)
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
