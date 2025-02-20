import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["all", "checkbox", "disable"];
  static values = { count: Number };

  connect() {
    this.toggleCheckbox();

    this.element.addEventListener("change", this.#toggleChangeListener.bind(this), {passive: true});
  }

  toggleAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = this.allTarget.checked;
    });

    this.countValue = this.allTarget.checked ? this.checkboxTargets.length : 0;

    this.#toggleDisabled();
  }

  toggleCheckbox() {
    this.countValue = this.#checkedCount();
    this.allTarget.checked = this.#allChecked();

    this.#toggleDisabled();
  }

  countValueChanged() {
    window.dispatchEvent(
      new CustomEvent("checked:updated", { detail: { count: this.countValue } })
    );
  }

  // private

  // Delegate events for targets (this ensures we catch events from newly-added elements after an ajax action)
  #toggleChangeListener(event) {
    if (event.target == this.allTarget) {
      this.toggleAll();
    } else if (this.checkboxTargets.includes(event.target)) {
      this.toggleCheckbox();
    }
  }

  #checkedCount() {
    return this.checkboxTargets.filter((checkbox) => checkbox.checked).length;
  }

  #allChecked() {
    return this.countValue === this.checkboxTargets.length;
  }

  #closeDetails(elmnt) {
    if (elmnt.getElementsByTagName('details').length == 0)
      return;

   Array.from(elmnt.getElementsByTagName('details')).forEach((element) => element.open = false);
 }

  #toggleDisabled() {
    if (!this.hasDisableTarget) {
      return;
    }

    if (this.#checkedCount() === 0) {
      this.disableTargets.forEach((element) => element.classList.add("disabled"));
      this.disableTargets.forEach(this.#closeDetails);
    } else {
      this.disableTargets.forEach((element) => element.classList.remove("disabled"));
    }
  }
}
