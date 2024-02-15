import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["control", "content", "chevron"];
  static values = { selector: String };

  disableIfPresent(event) {
    const input = event.currentTarget;
    const disable = !!this.#inputValue(input); // Coerce value to boolean

    this.controlTargets.forEach((target) => {
      target.disabled = disable;
    });

    // Focus when enabled
    if (!disable) {
      this.controlTargets[0].focus();
    }
  }

  enableIfPresent(event) {
    const input = event.currentTarget;
    const enable = !!this.#inputValue(input);

    this.controlTargets.forEach((target) => {
      target.disabled = !enable;
    });
  }

  toggleDisplay(event) {
    const input = event.currentTarget;
    this.contentTargets.forEach((t) => {
      t.style.display = input.dataset.toggleShow === "true" ? "block" : "none";
    });
  }

  toggleAdvancedSettings(event) {
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("icon-chevron-down");
      this.chevronTarget.classList.toggle("icon-chevron-up");
    }

    const element = document.querySelector(this.selectorValue);
    element.style.display = element.style.display === "none" ? "block" : "none";
  }

  // private

  // Return input's value, but only if it would be submitted by a form
  // Radio buttons not supported (yet)
  #inputValue(input) {
    if (input.type != "checkbox" || input.checked) {
      return input.value;
    }
  }
}
