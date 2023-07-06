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
    this.arrowTarget.dataset.collapsedClass.split(" ").forEach((className) => {
      this.arrowTarget.classList.remove(className);
    });
    this.arrowTarget.dataset.expandedClass.split(" ").forEach((className) => {
      this.arrowTarget.classList.add(className);
    });
  }
  #hide() {
    this.menuTarget.classList.add("hidden");
    this.arrowTarget.dataset.expandedClass.split(" ").forEach((className) => {
      this.arrowTarget.classList.remove(className);
    });
    this.arrowTarget.dataset.collapsedClass.split(" ").forEach((className) => {
      this.arrowTarget.classList.add(className);
    });
  }
}
