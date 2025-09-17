import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["content"];

  connect() {
    super.connect();
    window.addEventListener("click", this.#hideIfClickedOutside);
  }

  disconnect() {
    window.removeEventListener("click", this.#hideIfClickedOutside);
  }

  toggle() {
    this.contentTarget.classList.toggle("show");
  }

  #hideIfClickedOutside = (event) => {
    if (this.element.contains(event.target)) {
      return;
    }
    this.#hide();
  };

  #hide() {
    this.contentTarget.classList.remove("show");
  }
}
