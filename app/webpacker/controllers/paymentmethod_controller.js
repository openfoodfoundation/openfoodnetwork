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

    const stripeCardSelector =
      this.application.getControllerForElementAndIdentifier(
        document
          .getElementById(event.target.dataset.paymentmethodId)
          .querySelector('[data-controller="stripe-cards"]'),
        "stripe-cards"
      );
    stripeCardSelector?.initSelectedCard();
  }

  setPaymentMethod(paymentMethodContainerId) {
    Array.from(
      document.getElementsByClassName("paymentmethod-container")
    ).forEach((container) => {
      const enabled = container.id === paymentMethodContainerId

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
