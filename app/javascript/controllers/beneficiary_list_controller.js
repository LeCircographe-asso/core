import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "rows"]
  static values = { searchUrl: String, nextIndex: { type: Number, default: 0 } }

  addRow() {
    // Index unique et jamais réutilisé (même après suppression d'une ligne) :
    // évite que deux lignes partagent le même groupe de radios "formule".
    const html = this.templateTarget.innerHTML.replaceAll("__INDEX__", this.nextIndexValue)
    this.nextIndexValue++
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.dispatch("changed")
  }

  removeRow(event) {
    event.target.closest("[data-beneficiary-list-target='row']").remove()
    this.dispatch("changed")
  }

  async search(event) {
    const input = event.target
    const row = input.closest("[data-beneficiary-list-target='row']")
    const query = input.value.trim()
    const resultsEl = row.querySelector("[data-beneficiary-list-target='results']")

    if (query.length < 2) {
      resultsEl.innerHTML = ""
      return
    }

    const url = new URL(this.searchUrlValue, window.location.origin)
    url.searchParams.set("q", query)
    this.selectedPersonIds().forEach((id) => url.searchParams.append("exclude_ids[]", id))

    const response = await fetch(url, { headers: { Accept: "text/html" } })
    resultsEl.innerHTML = response.ok ? await response.text() : ""
  }

  selectPerson(event) {
    const button = event.currentTarget
    const row = button.closest("[data-beneficiary-list-target='row']")

    row.querySelector("[data-beneficiary-list-target='personIdField']").value = button.dataset.personId
    row.querySelector("[data-beneficiary-list-target='selectedName']").textContent = button.dataset.personName
    row.querySelector("[data-beneficiary-list-target='searchInput']").value = ""
    row.querySelector("[data-beneficiary-list-target='results']").innerHTML = ""
    this.dispatch("changed")
  }

  selectedPersonIds() {
    return Array.from(this.rowsTarget.querySelectorAll("[data-beneficiary-list-target='personIdField']"))
      .map((input) => input.value)
      .filter((value) => value !== "")
  }
}
