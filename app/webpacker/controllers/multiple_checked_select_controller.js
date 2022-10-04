import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["button", "caret", "options", "option", "filter"];

  connect() {
    this.buttonTarget.addEventListener("click", this.toggleOptions);
    document.addEventListener("click", this.closeOptions);
    this.filterTarget.addEventListener("input", this.filterOptions);
  }

  disconnect() {
    document.removeEventListener("click", this.closeOptions);
  }

  // private methods

  filterOptions = (e) => {
    const filter = e.target.value.toLowerCase();
    this.optionTargets.forEach((option) => {
      if (option.dataset["label"].toLowerCase().includes(filter)) {
        option.classList.remove("hidden");
      } else {
        option.classList.add("hidden");
      }
    });
  };

  toggleOptions = () => {
    this.optionsTarget.classList.toggle("hidden");
    this.caretTarget.classList.toggle("icon-caret-down");
    this.caretTarget.classList.toggle("icon-caret-up");
  };

  closeOptions = (e) => {
    if (!this.element.contains(e.target)) {
      this.optionsTarget.classList.add("hidden");
      this.caretTarget.classList.remove("icon-caret-up");
      this.caretTarget.classList.add("icon-caret-down");
    }
  };
}
