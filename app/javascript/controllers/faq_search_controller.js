import { Controller } from "@hotwired/stimulus"
import { prefersReducedMotion } from "lib/gsap/animation_prefs"

// Everyday words people type, mapped to the words the answers actually use (accent-free,
// singular). "prix" finds "tarif" and "€", "ou" finds "adresse"... Extend freely.
const SYNONYMS = [
  ["prix", "tarif", "cout", "cher", "payer", "paiement", "argent", "euro", "€", "gratuit", "reduit"],
  ["horaire", "heure", "ouvert", "ouverture", "quand", "creneau", "jour"],
  ["adresse", "ou", "acces", "venir", "trouver", "metro", "bus", "tram", "velo", "parking", "plan"],
  ["materiel", "equipement", "agres", "trapeze", "tapis", "accroche", "matos"],
  ["adhesion", "adherer", "inscription", "inscrire", "membre", "carte"],
  ["debutant", "debute", "debuter", "commencer", "premiere", "novice"],
  ["benevole", "aider", "aide", "soutenir", "soutien", "don"],
  ["contact", "ecrire", "ecris", "message", "mail", "joindre", "question"]
]

const STOP_WORDS = new Set([
  "de", "du", "des", "la", "le", "les", "un", "une", "et", "en", "au", "aux", "est", "il", "y",
  "je", "tu", "on", "nous", "vous", "ce", "ca", "se", "sa", "son", "ses", "mon", "ma", "mes",
  "qui", "que", "quoi", "pour", "avec", "dans", "sur", "par", "pas", "ne", "faut", "peut", "peux"
])

// FAQ page (app/views/pages/faq.html.erb): instant search over questions and answers,
// category shortcuts that scroll smoothly to their group and follow the reading, and opening
// the question named by the URL anchor (/faq#horaires). Without JS the page still works:
// every question is a native <details>, every shortcut a plain anchor.
export default class extends Controller {
  static targets = ["input", "item", "group", "chip", "chipRow", "empty", "status", "chips"]

  connect () {
    this.lockedUntil = 0
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

  filter () {
    const words = this.#words(this.inputTarget.value)
    let shown = 0

    this.itemTargets.forEach((item) => {
      if (item.dataset.searchText === undefined) item.dataset.searchText = ` ${this.#normalize(item.textContent)}`
    })
    // Per word, the word itself first; its synonyms only when the word is found nowhere.
    const termsPerWord = words.map((word) => {
      const { literal, synonyms } = this.#variants(word)
      const literalFound = this.itemTargets.some(item => this.#matches(item, literal))
      return literalFound ? literal : [...literal, ...synonyms]
    })

    this.itemTargets.forEach((item) => {
      const match = termsPerWord.every(terms => this.#matches(item, terms))
      item.hidden = !match
      if (match) shown++
      // A real query opens its matches, so the answers are readable right away.
      item.open = words.length > 0 && match && words.join("").length >= 3
    })

    this.groupTargets.forEach((group) => {
      const visible = this.itemTargets.some(item => group.contains(item) && !item.hidden)
      group.hidden = !visible
      const chip = this.chipTargets.find(c => c.dataset.group === group.id)
      if (chip) chip.hidden = !visible
    })

    this.emptyTarget.classList.toggle("hidden", shown > 0)
    this.statusTarget.textContent = words.length === 0 ? "" : `${shown} question${shown > 1 ? "s" : ""} trouvée${shown > 1 ? "s" : ""}`
  }

  clear () {
    this.inputTarget.value = ""
    this.filter()
  }

  suggest (event) {
    this.inputTarget.value = event.currentTarget.dataset.term
    this.filter()
    this.inputTarget.focus({ preventScroll: true })
  }

  // Shortcut click: smooth scroll to the group, just below the sticky shortcuts, without a
  // jump, a Turbo visit or the highlight flickering through the groups crossed on the way.
  activate (event) {
    const li = event.currentTarget.closest("[data-group]")
    const group = li && this.groupTargets.find(g => g.id === li.dataset.group)
    if (!group) return
    event.preventDefault()

    this.#setActive(group.id)
    this.lockedUntil = Date.now() + 1000
    const offset = this.chipsTarget.getBoundingClientRect().height + this.#stickyTop() + 12
    const top = group.getBoundingClientRect().top + window.scrollY - offset
    window.scrollTo({ top, behavior: prefersReducedMotion() ? "auto" : "smooth" })
    history.replaceState(history.state, "", `#${group.id}`)
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
      if (Date.now() < this.lockedUntil) return
      const current = this.groupTargets.find(group => !group.hidden && this.inView.get(group.id))
      if (current) this.#setActive(current.id)
    }, { rootMargin: "-35% 0px -55% 0px" })
    this.groupTargets.forEach(group => this.observer.observe(group))
  }

  #setActive (groupId) {
    this.chipTargets.forEach((li) => {
      const link = li.querySelector("a")
      const active = li.dataset.group === groupId
      if (active === link.hasAttribute("data-active")) return
      link.toggleAttribute("data-active", active)
      if (active) {
        link.setAttribute("aria-current", "true")
        this.#revealChip(li)
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }

  // Phones: bring the active shortcut into view in the scrolling row, centred, only if it is
  // not fully visible already (no movement for nothing).
  #revealChip (li) {
    const row = this.chipRowTarget
    if (row.scrollWidth <= row.clientWidth) return
    const rowBox = row.getBoundingClientRect()
    const chipBox = li.getBoundingClientRect()
    const margin = 16
    if (chipBox.left >= rowBox.left + margin && chipBox.right <= rowBox.right - margin) return
    const left = row.scrollLeft + (chipBox.left - rowBox.left) - (rowBox.width - chipBox.width) / 2
    row.scrollTo({ left: Math.max(0, left), behavior: prefersReducedMotion() ? "auto" : "smooth" })
  }

  // Stack the shortcuts under the navbar only if the navbar really sticks: it is declared
  // sticky but wrapped in an inline <turbo-frame> no taller than itself, so today it
  // scrolls away and the shortcuts go to the very top. CSSOM, not a style attribute (CSP).
  #syncStickyTop () {
    this.element.style.setProperty("--faq-sticky-top", `${this.#stickyTop()}px`)
  }

  #stickyTop () {
    const nav = document.querySelector("nav.sticky")
    const sticks = nav && nav.parentElement.getBoundingClientRect().height > nav.getBoundingClientRect().height + 1
    return sticks ? Math.round(nav.getBoundingClientRect().height) : 0
  }

  // Query words: accent-free, lower case, 2+ letters ("où" → "ou"), without the little words
  // that carry no meaning ("combien de points" searches "combien" and "points").
  #words (text) {
    return this.#normalize(text).split(/[^a-z0-9€]+/)
      .filter(w => (w.length >= 2 || w === "€") && !STOP_WORDS.has(w))
  }

  // { literal: the word and its form without a plural "s"/"x" ("horaires" → "horaire", while
  // "prix" stays known as "prix"), synonyms: the rest of its SYNONYMS group }. Words under
  // 3 letters ("ou") would match almost any text: they only count through their synonyms.
  #variants (word) {
    // A word already in SYNONYMS keeps its own spelling: "prix" must not become "pri", whose
    // matches ("prise", "priorité") would hide the price synonyms.
    const known = SYNONYMS.find(list => list.includes(word))
    const singular = !known && word.length > 3 ? word.replace(/[sx]$/, "") : word
    const group = known || SYNONYMS.find(list => list.includes(singular)) || []
    const long = term => term.length >= 3 || term === "€"
    const literal = [...new Set([word, singular])].filter(long)
    const synonyms = group.filter(term => !literal.includes(term) && long(term))
    return literal.length ? { literal, synonyms } : { literal: synonyms, synonyms: [] }
  }

  // A term matches at the start of a word ("jour" finds "journée", not "toujours").
  #matches (item, terms) {
    return terms.some(term => term === "€" ? item.dataset.searchText.includes("€") : new RegExp(`[^a-z0-9]${term}`).test(item.dataset.searchText))
  }

  #normalize (text) {
    return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
  }
}
