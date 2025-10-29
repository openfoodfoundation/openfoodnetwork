import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["checkout", "guest", "summary"];
  static values = {
    distributor: String,
    session: { type: String, default: "guest-checkout" },
  };

  connect() {
    if (this.hasSummaryTarget) {
      window.addEventListener("beforeunload", this.handlePageUnload);
    }

    if (!this.hasGuestTarget) {
      return;
    }

    if (this.usingGuestCheckout()) {
      this.showCheckout();
    }
  }

  disconnect() {
    this.removeUnloadEvent();
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

  handlePageUnload(event) {
    event.preventDefault();
    event.returnValue = I18n.t("admin.unsaved_confirm_leave");
  }

  removeUnloadEvent() {
    if (this.hasSummaryTarget) {
      window.removeEventListener("beforeunload", this.handlePageUnload);
    }
  }
}
