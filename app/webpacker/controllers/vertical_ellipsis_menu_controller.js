import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["content"];

  connect() {
    super.connect();
    window.addEventListener("click", (e) => {
      if (this.element.contains(e.target)) return;
      this.#hide();
    });
  }

  toggle() {
    this.contentTarget.classList.toggle("show");
  }

  #hide() {
    this.contentTarget.classList.remove("show");
  }
}
