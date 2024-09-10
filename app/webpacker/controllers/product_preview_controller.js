import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    // open the modal when html is rendering to avoid opening a blank modal
    this.#open()
  }

  // private

  #open() {
    // dispatch "product-preview:open" event to trigger modal->open action
    // see views/admin/product_v3/index.html.haml
    this.dispatch("open");
  }
}
