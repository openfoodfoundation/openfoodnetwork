import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    window.addEventListener("trix-change", this.#trixChange);
  }

  #trixChange = (event) => {
    // trigger a change event on the form that contains the Trix editor
    event.target.form.dispatchEvent(new Event("change", { bubbles: true }));
  };
}
