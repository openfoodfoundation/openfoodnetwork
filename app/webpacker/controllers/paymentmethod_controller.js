import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ["panel"];

  selectPaymentMethod(event) {
    this.panelTarget.innerHTML = `<span>${event.target.dataset.paymentmethodDescription}</span>`;
    this.panelTarget.style.display = "block";
  }
}
