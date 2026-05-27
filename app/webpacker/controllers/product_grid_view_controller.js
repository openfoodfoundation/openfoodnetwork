import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["loading", "products"];
  static classes = ["hidden"];

  updateProducts(ev) {
    const orderCycleId = ev.detail.orderCycleId;
    // Updating the turbo-frame source will reload the frame
    this.element.src = `/order_cycles/${orderCycleId}/products`;

    // show loading
    this.loadingTarget.classList.remove(this.hiddenClass);
    this.productsTarget.classList.add(this.hiddenClass);
  }
}
