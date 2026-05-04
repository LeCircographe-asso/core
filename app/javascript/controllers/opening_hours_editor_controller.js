import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["closedCheckbox", "timeInput", "finalInput", "previewContainer"]

  connect() {
    this.initializeFromInputs()
  }

  toggleClosed(event) {
    const checkbox = event.currentTarget
    const day = checkbox.dataset.day
    const timeInput = this.timeInputFor(day)
    const finalInput = this.finalInputFor(day)

    if (!timeInput || !finalInput) return

    if (checkbox.checked) {
      timeInput.style.display = "none"
      finalInput.value = "Fermé"
      this.updatePreview(day, "Fermé")
      return
    }

    timeInput.style.display = "block"
    this.resetDaySelectors(day)
    this.updateFromSelectors(day)
  }

  updateFromSelectors(eventOrDay) {
    const day = typeof eventOrDay === "string" ? eventOrDay : eventOrDay.currentTarget.dataset.day
    const openHour = this.inputValue(`open_hour_${day}`)
    const openMinute = this.inputValue(`open_minute_${day}`)
    const closeHour = this.inputValue(`close_hour_${day}`)
    const closeMinute = this.inputValue(`close_minute_${day}`)

    if ([openHour, openMinute, closeHour, closeMinute].some((value) => value === null)) return

    const timeValue = `${openHour.padStart(2, "0")}:${openMinute.padStart(2, "0")} - ${closeHour.padStart(2, "0")}:${closeMinute.padStart(2, "0")}`
    const finalInput = this.finalInputFor(day)
    if (finalInput) finalInput.value = timeValue
    this.updatePreview(day, timeValue)
  }

  initializeFromInputs() {
    this.closedCheckboxTargets.forEach((checkbox) => {
      const day = checkbox.dataset.day
      const finalInput = this.finalInputFor(day)
      const timeInput = this.timeInputFor(day)
      if (!finalInput || !timeInput) return

      this.updatePreview(day, finalInput.value)
      if (checkbox.checked) {
        timeInput.style.display = "none"
      } else {
        timeInput.style.display = "block"
        this.initializeSelectors(day, finalInput.value)
      }
    })
  }

  updatePreview(day, value) {
    if (!this.hasPreviewContainerTarget) return

    const rows = this.previewContainerTarget.querySelectorAll("tr")
    rows.forEach((row) => {
      const rowText = row.textContent.toLowerCase()
      if (!rowText.includes(day.toLowerCase())) return

      const hourCell = row.querySelector("td:nth-child(2)")
      if (!hourCell) return

      if (value.toLowerCase() === "fermé") {
        hourCell.innerHTML = `
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
            <i class="fas fa-times-circle mr-1"></i>
            Fermé
          </span>
        `
      } else {
        hourCell.innerHTML = `
          <span class="text-gray-800">
            <i class="far fa-clock text-[#1F5C55] mr-1 hidden sm:inline"></i>
            ${value}
          </span>
        `
      }
    })
  }

  initializeSelectors(day, timeValue) {
    if (!timeValue || timeValue.toLowerCase() === "fermé") return

    const [openTime, closeTime] = timeValue.split(" - ")
    if (!openTime || !closeTime) return

    const [openHour, openMinute] = openTime.split(":")
    const [closeHour, closeMinute] = closeTime.split(":")

    this.setInputValue(`open_hour_${day}`, openHour)
    this.setInputValue(`open_minute_${day}`, openMinute)
    this.setInputValue(`close_hour_${day}`, closeHour)
    this.setInputValue(`close_minute_${day}`, closeMinute)
  }

  resetDaySelectors(day) {
    this.setInputValue(`open_hour_${day}`, "14")
    this.setInputValue(`open_minute_${day}`, "0")
    this.setInputValue(`close_hour_${day}`, "22")
    this.setInputValue(`close_minute_${day}`, "0")
  }

  inputValue(name) {
    const input = this.element.querySelector(`select[name="${name}"]`)
    return input ? input.value : null
  }

  setInputValue(name, value) {
    const input = this.element.querySelector(`select[name="${name}"]`)
    if (input) input.value = value
  }

  timeInputFor(day) {
    return this.timeInputTargets.find((element) => element.dataset.day === day)
  }

  finalInputFor(day) {
    return this.finalInputTargets.find((element) => element.dataset.day === day)
  }
}
