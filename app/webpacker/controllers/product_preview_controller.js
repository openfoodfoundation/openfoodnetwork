import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    // open the modal before rendering the html to avoid opening a blank modal
    // TODO other option is having a controller in the stream html that would dispatch the open element on connect
    window.addEventListener("turbo:before-stream-render", this.#open.bind(this));
  }

  disconnect() {
    window.removeEventListener("turbo:before-stream-render", this.#open.bind(this));
  }

  // private

  #open() {
    // dispatch "product-preview:open" event to trigger modal->open action
    // see views/admin/product_v3/index.html.haml
    this.dispatch("open");
  }
}
