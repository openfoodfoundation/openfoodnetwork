import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["chevron"];
  static values = { selector: String };

  toggle(event) {
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("icon-chevron-down");
      this.chevronTarget.classList.toggle("icon-chevron-up");
    }

    const element = document.querySelector(this.selectorValue);
    element.style.display = element.style.display === "none" ? "block" : "none";
  }
}
