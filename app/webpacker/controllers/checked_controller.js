import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["all", "checkbox", "disable"];

  connect() {
    this.toggleCheckbox();
  }

  toggleAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = this.allTarget.checked;
    });
    this.#toggleDisabled();
  }

  toggleCheckbox() {
    this.allTarget.checked = this.checkboxTargets.every((checkbox) => checkbox.checked);
    this.#toggleDisabled();
  }

  // private

  #toggleDisabled() {
    if (!this.hasDisableTarget) {
      return;
    }

    if (this.#noneChecked()) {
      this.disableTargets.forEach((element) => element.classList.add("disabled"));
    } else {
      this.disableTargets.forEach((element) => element.classList.remove("disabled"));
    }
  }

  #noneChecked() {
    return this.checkboxTargets.every((checkbox) => !checkbox.checked);
  }
}
