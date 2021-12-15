import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ["paymentMethod"];

  selectPaymentMethod(event) {
    const paymentMethodContainerId = event.target.dataset.paymentmethodId;
    Array.from(
      document.getElementsByClassName("paymentmethod-container")
    ).forEach((e) => {
      if (e.id === paymentMethodContainerId) {
        e.style.display = "block";
        this.addRequiredAttributeOnInputIfNeeded(e);
        this.removeDisabledAttributeOnInput(e);
      } else {
        e.style.display = "none";
        this.removeRequiredAttributeOnInput(e);
        this.addDisabledAttributeOnInput(e);
      }
    });
  }

  getFormElementsArray(container) {
    return Array.from(container.querySelectorAll("input, select, textarea"));
  }

  addDisabledAttributeOnInput(container) {
    this.getFormElementsArray(container).forEach((i) => {
      i.disabled = true;
    });
  }

  removeDisabledAttributeOnInput(container) {
    this.getFormElementsArray(container).forEach((i) => {
      i.disabled = false;
    });
  }

  removeRequiredAttributeOnInput(container) {
    this.getFormElementsArray(container).forEach((i) => {
      if (i.required) {
        i.dataset.required = i.required;
        i.required = false;
      }
    });
  }

  addRequiredAttributeOnInputIfNeeded(container) {
    this.getFormElementsArray(container).forEach((i) => {
      if (i.dataset.required === "true") {
        i.required = true;
      }
    });
  }
}
