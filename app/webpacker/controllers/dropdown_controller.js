import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["arrow", "menu"];

  connect() {
    this.#hide();
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.#show();
    } else {
      this.#hide();
    }
  }

  #show() {
    this.menuTarget.classList.remove("hidden");
    this.arrowTarget.classList.remove(this.arrowTarget.dataset.collapsedClass);
    this.arrowTarget.classList.add(this.arrowTarget.dataset.expandedClass);
  }
  #hide() {
    this.menuTarget.classList.add("hidden");
    this.arrowTarget.classList.remove(this.arrowTarget.dataset.expandedClass);
    this.arrowTarget.classList.add(this.arrowTarget.dataset.collapsedClass);
  }
}
