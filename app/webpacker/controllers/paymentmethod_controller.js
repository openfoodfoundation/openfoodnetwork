import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ["paymentMethod"];

  connect() {
    this.selectPaymentMethod();
  }

  selectPaymentMethod(event = null) {
    const paymentMethodContainerId = event
      ? event.target.dataset.paymentmethodId
      : null;
    Array.from(
      document.getElementsByClassName("paymentmethod-container")
    ).forEach((e) => {
      if (e.id === paymentMethodContainerId) {
        e.style.display = "block";
        this.addRequiredAttributeOnInputIfNeeded(e);
      } else {
        e.style.display = "none";
        this.removeRequiredAttributeOnInput(e);
      }
    });
  }

  removeRequiredAttributeOnInput(container) {
    Array.from(container.getElementsByTagName("input")).forEach((i) => {
      if (i.required) {
        i.dataset.required = i.required;
        i.required = false;
      }
    });
  }

  addRequiredAttributeOnInputIfNeeded(container) {
    Array.from(container.getElementsByTagName("input")).forEach((i) => {
      if (i.dataset.required === "true") {
        i.required = true;
      }
    });
  }
}
