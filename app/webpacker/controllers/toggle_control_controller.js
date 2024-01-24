import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["control"];

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
  //todo: can a new method toggleDisplay replace ToggleController?
  //todo: can toggleDisplay with optional chevron-target replace RemoteToggleController?

  // private

  // Return input's value, but only if it would be submitted by a form
  // Radio buttons not supported (yet)
  #inputValue(input) {
    if (input.type != "checkbox" || input.checked) {
      return input.value;
    }
  }
}
