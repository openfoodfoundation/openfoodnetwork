import { Controller } from "stimulus";
export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.inputTargets.forEach((input) => {
      if (input.checked) {
        this.setPaymentMethod(input.dataset.paymentmethodId);
      }
    });
  }

  selectPaymentMethod(event) {
    this.setPaymentMethod(event.target.dataset.paymentmethodId);
    // Send an event to the right (ie. the one with the same paymentmethodId)
    // StripeCardsController to initialize the form elements with the selected card
    const customEvent = new CustomEvent("stripecards:initSelectedCard", {
      detail: event.target.dataset.paymentmethodId,
    });
    document.dispatchEvent(customEvent);
  }

  setPaymentMethod(paymentMethodContainerId) {
    Array.from(
      document.getElementsByClassName("paymentmethod-container")
    ).forEach((container) => {
      const enabled =
        container.dataset.paymentmethodId === paymentMethodContainerId;

      if (enabled) {
        container.style.display = "block";
        this.toggleFieldsEnabled(container, enabled);
      } else {
        container.style.display = "none";
        this.toggleFieldsEnabled(container, enabled);
      }
    });
  }

  toggleFieldsEnabled(container, enabled) {
    this.subFormElements(container).forEach((field) => {
      field.disabled = !enabled;
    });
  }

  subFormElements(container) {
    return Array.from(container.querySelectorAll("input, select, textarea"));
  }
}
