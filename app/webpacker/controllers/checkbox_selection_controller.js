import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["checkbox", "errorMessage"]

  get disableElements() {
    return document.querySelectorAll("[data-checkbox-selection-button]")
  }

  connect() {
    this.handleError(false)
  }

  disableButtons() {
    const groupStates = this.checkboxTargets.reduce((acc, element) => {
     const group = element.getAttribute("data-group")

      if (group in acc) {
        acc[group].push(element.checked)
        return acc
      }

      acc[group] = [element.checked]
      return acc
    }, {})

    const isAllUnchecked = Object.values(groupStates).flatMap((values) => values.every((isChecked) => !isChecked)).some((checked) => checked)

    this.disableElements.forEach((element) => {
      element.disabled = isAllUnchecked
    })

    this.handleError(isAllUnchecked)
  }

  handleError(isVisible) {
    const error = this.errorMessageTarget
    error.style.display = isVisible ? "block" : "none"
  }
}
