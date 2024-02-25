import { Controller } from "stimulus";

export default class extends Controller {

  connect() {
    document.body.addEventListener("click", this.#close.bind(this));
    this.element.addEventListener("click", this.#stopPropagation.bind(this));
  }

  disconnect() {
    document.removeEventListener("click", this.#close);
    document.removeEventListener("click", this.#stopPropagation);
  }

  closeOnMenu(event) {
    this.#close();
    this.#stopPropagation(event);
  }

  // private

  #close(event) {
    this.element.open = false;
  }

  #stopPropagation(event) {
    event.stopPropagation();
  }
}
