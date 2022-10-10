import ApplicationController from "./application_controller";
export default class extends ApplicationController {
  static targets = [
    "allowGuestOrders",
    "allowToChangeOrders",
    "shopFrontVisible",
  ];

  static values = {
    allowGuestOrders: Boolean,
  };

  connect() {
    super.connect();
  }

  toggleRow(event) {
    if (!location.hash == "") {
      location.hash = "";
    }

    let allowGuestOrders = this.hasAllowGuestOrdersTarget
      ? this.allowGuestOrdersTarget.checked
      : this.allowGuestOrdersValue;

    this.stimulate(
      "EnterpriseEdit#toggle_guest_order_row",
      event.target,
      this.shopFrontVisibleTarget.checked,
      this.allowToChangeOrdersTarget.checked,
      allowGuestOrders
    );
  }
}
