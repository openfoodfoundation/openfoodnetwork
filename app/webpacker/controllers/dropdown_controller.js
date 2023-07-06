import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["arrow", "menu"];

  connect() {
    this.#hide();
    document.addEventListener("click", this.#onBodyClick.bind(this));
  }

  disconnect() {
    document.removeEventListener("click", this.#onBodyClick);
  }

  toggle() {
    if (this.menuTarget.classList.contains("hidden")) {
      this.#show();
    } else {
      this.#hide();
    }
  }

  #onBodyClick(event) {
    if (!this.element.contains(event.target)) {
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
