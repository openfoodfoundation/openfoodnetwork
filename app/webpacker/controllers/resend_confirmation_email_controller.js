import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
  }

  confirm() {
    const order_ids = [];
    document
      .querySelectorAll("#listing_orders input[name='order_ids[]']:checked")
      .forEach((checkbox) => {
        order_ids.push(checkbox.value);
      });

    this.stimulate("ResendConfirmationEmailReflex#confirm", order_ids);
  }
}
