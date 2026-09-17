import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["products"];

  updateProducts(ev) {
    if (this.hasProductsTarget) {
      this.productsTarget.style.display = "none";
    }

    const orderCycleId = ev.detail.orderCycleId;
    // Updating the turbo-frame source will reload the frame
    this.element.src = `/order_cycles/${orderCycleId}/products`;
  }
}
