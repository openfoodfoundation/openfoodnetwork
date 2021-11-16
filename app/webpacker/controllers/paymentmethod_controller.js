import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ["paymentMethod"];

  connect() {
    this.hideAll();
  }

  selectPaymentMethod(event) {
    this.hideAll();
    const paymentMethodContainerId = event.target.dataset.paymentmethodId;
    const paymentMethodContainer = document.getElementById(
      paymentMethodContainerId
    );
    paymentMethodContainer.style.display = "block";
  }

  hideAll() {
    Array.from(
      document.getElementsByClassName("paymentmethod-container")
    ).forEach((e) => {
      e.style.display = "none";
    });
  }
}
