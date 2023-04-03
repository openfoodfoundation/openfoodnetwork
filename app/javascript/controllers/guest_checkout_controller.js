import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["checkout", "guest"];
  static values = {
    distributor: String,
    session: { type: String, default: "guest-checkout" },
  };

  connect() {
    if (!this.hasGuestTarget) {
      return;
    }

    if (this.usingGuestCheckout()) {
      this.showCheckout();
    }
  }

  login() {
    window.dispatchEvent(new Event("login:modal:open"));
  }

  showCheckout() {
    this.checkoutTarget.style.display = "block";
    this.guestTarget.style.display = "none";
  }

  guestSelected() {
    this.showCheckout();
    sessionStorage.setItem(this.sessionValue, this.distributorValue);
  }

  usingGuestCheckout() {
    return sessionStorage.getItem(this.sessionValue) === this.distributorValue;
  }
}
