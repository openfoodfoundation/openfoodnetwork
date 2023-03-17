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
    const checkboxes = document.querySelectorAll(
      "#listing_orders input[name='order_ids[]']:checked"
    );
    return Array.from(checkboxes).map((checkbox) => checkbox.value);
  }
}
