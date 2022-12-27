import { ModalCancelController } from "./ModalCancelController";
import { useXSRFProtection } from "../mixins/useXSRFProtection";

export default class extends ModalCancelController {
  connect() {
    useXSRFProtection(this);
    this.cookieXSRFToken = this.getXSRFCookieValue.bind(this)(document.cookie);
  }

  getSelectedOrders() {
    const tbody = document.querySelector("table#listing_orders tbody");
    const checkboxes = tbody.querySelectorAll(
      "input[type=checkbox][name=order]"
    );

    return Array.from(checkboxes)
      .filter((chkbx) => chkbx.checked == true)
      .map((chkbx) => chkbx.id);
  }

  callback(confirm, sendEmailCancellation, restock_items) {
    if (confirm) {
      return this.cancelOrder(
        this.getSelectedOrders(),
        sendEmailCancellation,
        restock_items
      );
    }
  }

  cancelOrder(order_ids, sendEmailCancellation, restock_items) {
    return fetch(
      `/admin/orders/bulk_cancel?order_ids=${order_ids}&send_cancellation_email=${sendEmailCancellation}&restock_items=${restock_items}`,
      {
        method: "POST",
        headers: {
          "Content-type": "application/json; charset=UTF-8",
          "X-XSRF-TOKEN": this.cookieXSRFToken,
        },
      }
    ).then(() => window.location.reload());
  }

  cancelSelectedOrders() {
    this.showModal(this.callback);
  }
}
