import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["chevron", "classUpdate"];
  static values = { selector: String };

  toggleDisplay(_event) {
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("ofn-i_005-caret-down");
      this.chevronTarget.classList.toggle("ofn-i_006-caret-up");
    }

    if (this.hasClassUpdateTarget) {
      this.classUpdateTargets.forEach((t) => {
        t.classList.toggle("closed");
        t.classList.toggle("open");
      });
    }

    const element = document.querySelector(this.selectorValue);
    element.style.display = element.style.display === "none" ? "block" : "none";
  }
}
