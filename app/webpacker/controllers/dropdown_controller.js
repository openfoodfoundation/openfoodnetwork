import { Controller } from "stimulus";

// Close a <details> element when click outside
export default class extends Controller {
  #closeBound;

  connect() {
    this.#closeBound = this.#close.bind(this);
    document.body.addEventListener("click", this.#closeBound);
  }

  disconnect() {
    document.body.removeEventListener("click", this.#closeBound);
  }

  closeOnMenu() {
    this.element.open = false;
  }

  // private

  #close(event) {
    if (!this.element.contains(event.target)) {
      this.element.open = false;
    }
  }
}
