import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
  }

  // abstract
  confirm(action) {
    this.stimulate(action, this.getOrdersIds());
  }

  // private
  getOrdersIds() {
    const order_ids = [];
    document
      .querySelectorAll("#listing_orders input[name='order_ids[]']:checked")
      .forEach((checkbox) => {
        order_ids.push(checkbox.value);
      });
    return order_ids;
  }
}
