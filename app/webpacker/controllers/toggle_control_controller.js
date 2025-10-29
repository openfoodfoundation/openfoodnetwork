import { Controller } from "stimulus";

const BUTTON_TYPES = ["submit", "button"];

// Toggle state of a control based on a condition.
//
// 1. When an action occurs on an element,
// 2. The element's value is inspected, and
// 3. The related control(s) are changed state
//
export default class extends Controller {
  static targets = ["control", "content", "chevron"];
  static values = { selector: String, match: String };

  disableIfPresent(event) {
    const present = !!this.#inputValue(event.currentTarget); // Coerce value to boolean

    this.#toggleDisabled(present);
  }

  enableIfPresent(event) {
    const present = !!this.#inputValue(event.currentTarget); // Coerce value to boolean

    this.#toggleDisabled(!present);
  }

  // Display the "content" target if element has data-toggle-show="true"
  // (TODO: why not use the "control" target?)
  toggleDisplay(event) {
    const input = event.currentTarget;
    this.contentTargets.forEach((t) => {
      t.style.display = input.dataset.toggleShow === "true" ? "block" : "none";
    });
  }

  // Toggle element specified by data-control-toggle-selector-value="<css selector>"
  // (TODO: give a more general name)
  toggleAdvancedSettings(event) {
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("icon-chevron-down");
      this.chevronTarget.classList.toggle("icon-chevron-up");
    }

    const element = document.querySelector(this.selectorValue);
    element.style.display = element.style.display === "none" ? "block" : "none";
  }

  // Display the control if selected value matches value in data-toggle-match="<value>"
  displayIfMatch(event) {
    const inputValue = this.#inputValue(event.currentTarget);

    this.#toggleDisplay(inputValue == this.matchValue);
  }

  // private

  #toggleDisabled(disable) {
    this.controlTargets.forEach((target) => {
      target.disabled = disable;
    });

    // Focus first when enabled and it's not a button
    if (!disable) this.#focusFieldControl();
  }

  #toggleDisplay(show) {
    this.controlTargets.forEach((target) => {
      target.style.display = show ? "block" : "none";
    });

    // Focus first when displayed
    if (show) this.#focusFieldControl();
  }

  // Return input's value, but only if it would be submitted by a form
  // Radio buttons not supported (yet)
  #inputValue(input) {
    if (input.type != "checkbox" || input.checked) {
      return input.value;
    }
  }

  #focusFieldControl() {
    const control = this.controlTargets[0];
    const isButton = BUTTON_TYPES.includes(control.type);
    if (!isButton) control.focus();
  }
}
