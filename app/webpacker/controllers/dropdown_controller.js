import { Controller } from "stimulus";

// Close a <details> element when click outside
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

  submitLink(event) {
    const link = event.currentTarget;
    const method = link.getAttribute('data-turbo-method');
    const confirmMessage = link.getAttribute('data-turbo-confirm');

    if (link && confirmMessage && [null, 'get'].includes(method)) {
      // Manualy visit link
      event.preventDefault();
      if (confirm(link.getAttribute('data-turbo-confirm'))) {
        Turbo.visit(link.href);
      }
    }

    this.closeOnMenu(event);
  }

  // private

  #close(event) {
    this.element.open = false;
  }

  #stopPropagation(event) {
    event.stopPropagation();
  }
}
