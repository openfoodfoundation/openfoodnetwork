import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
  }

  confirm() {
    const send_cancellation_email = document.querySelector(
      "#send_cancellation_email"
    ).checked;
    const restock_items = document.querySelector("#restock_items").checked;
    const order_ids = [];

    document
      .querySelectorAll("#listing_orders input[name='order_ids[]']:checked")
      .forEach((checkbox) => {
        order_ids.push(checkbox.value);
      });

    const params = {
      order_ids: order_ids,
      send_cancellation_email: send_cancellation_email,
      restock_items: restock_items,
    };
    this.stimulate("CancelOrdersReflex#confirm", params).then(() =>
      window.location.reload()
    );
  }
}
