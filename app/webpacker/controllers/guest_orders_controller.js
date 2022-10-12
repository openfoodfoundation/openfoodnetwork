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
    let allowGuestOrders = this.hasAllowGuestOrdersTarget
      ? this.allowGuestOrdersTarget.checked
      : this.allowGuestOrdersValue;

    if (!location.hash == "") {
      location.hash = "";
    }
    this.stimulate(
      "EnterpriseEdit#toggle_guest_order_row",
      event.target,
      this.shopFrontVisibleTarget.checked,
      this.allowToChangeOrdersTarget.checked,
      allowGuestOrders
    );
  }
}
