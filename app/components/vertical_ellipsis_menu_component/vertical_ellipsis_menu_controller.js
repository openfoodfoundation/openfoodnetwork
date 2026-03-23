import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["content"];

  connect() {
    super.connect();
    window.addEventListener("click", this.#hideIfClickedOutside);

    // Close menu when making a selection
    this.contentTarget.addEventListener("click", this.#selected.bind(this));
  }

  disconnect() {
    window.removeEventListener("click", this.#hideIfClickedOutside);
  }

  toggle() {
    this.#toggleShow();
  }

  #selected() {
    this.contentTarget.classList.add("selected");
  };

  #hideIfClickedOutside = (event) => {
    if (this.element.contains(event.target)) {
      return;
    }
    this.#toggleShow(false);
  };

  #toggleShow(force = undefined) {
    this.contentTarget.classList.toggle("show", force);
    this.contentTarget.classList.remove("selected");
  }
}
