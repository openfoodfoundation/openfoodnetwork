import { Controller } from "stimulus";
import TomSelect from "tom-select/dist/esm/tom-select.complete";

export default class extends Controller {
  connect() {
    this.control = new TomSelect(this.element, {
      create: true,
      plugins: ["dropdown_input"],
      labelField: "email",
      load: this.#load.bind(this),
      maxItems: 1,
      persist: false,
      searchField: ["email"],
      shouldLoad: (query) => query.length > 2,
      valueField: "email",
    });
  }

  disconnect() {
    if (this.control) this.control.destroy();
  }

  // private

  #load(query, callback) {
    const url = "/admin/search/known_users.json?q=" + encodeURIComponent(query);
    fetch(url)
      .then((response) => response.json())
      .then((json) => {
        callback({ items: json });
      })
      .catch((error) => {
        console.log(error);
        callback();
      });
  }
}
