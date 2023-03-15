import { Controller } from "stimulus";

const isAllFalse = (values) => values.every((isChecked) => !isChecked)
export default class extends Controller {
  static targets = ["checkbox", "errorMessage"]

  get disableElements() {
    return document.querySelectorAll("[data-checkbox-selection-button]")
  }

  get groupStates() {
    return this.checkboxTargets.reduce((acc, element) => {
      const { group } = element.dataset
      const groupValues = acc[group] || []

      return {
        ...acc,
        [group]: [...groupValues, element.checked]
      }
    }, {})
  }

  connect() {
    this.handleError(false)
  }

  disableButtons() {
    const isAllUnchecked = Object.values(this.groupStates).flatMap(isAllFalse).some(Boolean)

    this.disableElements.forEach((element) => {
      element.disabled = isAllUnchecked
    })

    this.handleError(isAllUnchecked)
  }

  handleError(isVisible) {
    const groups = this.groupStates
    const uncheckedGroup = Object.keys(groups).filter((group) => !groups[group].some(Boolean))

    const errorMessage = uncheckedGroup.length > 1
    ? I18n.t(`admin.order_cycles.checkout_options.no_methods`)
    : I18n.t(`admin.order_cycles.checkout_options.no_${uncheckedGroup.toString()}_methods`)

    const error = this.errorMessageTarget

    error.style.display = isVisible ? "block" : "none"
    error.innerHTML = errorMessage
  }
}
