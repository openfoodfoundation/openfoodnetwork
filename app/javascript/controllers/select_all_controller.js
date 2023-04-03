import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["all", "checkbox"];

  connect() {
    this.toggleCheckbox();
  }

  toggleAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = this.allTarget.checked;
    });
  }

  toggleCheckbox() {
    this.allTarget.checked = this.checkboxTargets.every(
      (checkbox) => checkbox.checked
    );
  }
}
