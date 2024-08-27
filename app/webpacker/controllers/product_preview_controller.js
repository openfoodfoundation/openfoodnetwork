import { Controller } from "stimulus";

export default class extends Controller {
  open() {
    // dispatch "product-preview:open" event to trigger modal->open action
    // see views/admin/product_v3/index.html.haml
    this.dispatch("open");
  }
}
