import { Controller } from "stimulus";

// The order cycle selector of a product page.
//
// Changing the order cycle empties the cart, so this asks first unless the cart is
// demonstrably empty. The shopfront layout opts out of Turbo Drive, so
// `data-turbo-confirm` isn't available to do the asking for us.
export default class extends Controller {
  static values = { confirm: String };

  submit() {
    if (!this.cartIsEmpty && !window.confirm(this.confirmValue)) {
      this.element.reset();
      return;
    }

    this.element.requestSubmit();
  }

  // The cart sidebar is re-rendered on every change of the cart, so its count is more
  // up to date than anything this page was served with. Without one, assume the worst.
  get cartIsEmpty() {
    return document.getElementById("cart-sidebar")?.dataset?.itemCount === "0";
  }
}
