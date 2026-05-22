import { Controller } from "stimulus";

export default class extends Controller {
  updateProducts(ev) {
    const orderCycleId = ev.detail.orderCycleId;
    // Updating the turbo-frame source will reload the frame
    this.element.src = `/order_cycles/${orderCycleId}/products`;
  }
}
