import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["outOfStockMessage"];

  onQuantityChange(e) {
    // find the out of stock message that matches the line item id
    const message = this.outOfStockMessageTargets.find((t) => {
      return t.dataset.lineItemId == e.currentTarget.dataset.lineItemId;
    });
    // if the max is reached, then display the out of stock message
    if (e.currentTarget.value > e.currentTarget.max) {
      message.style.display = "inline";
    } else {
      // otherwise, hide the out of stock message
      message.style.display = "none";
    }
  }
}
