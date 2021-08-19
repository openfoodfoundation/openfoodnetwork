import { Controller } from "stimulus";
export default class extends Controller {
  static targets = [
    "shippingMethodDescription",
    "shippingMethodDescriptionContent",
    "shippingMethodAddress",
    "shippingAddressCheckbox",
  ];
  connect() {
    // Hide shippingMethodDescription by default
    this.shippingMethodDescriptionTarget.style.display = "none";
    this.shippingMethodAddressTarget.style.display = "none";
  }

  selectShippingMethod(event) {
    const input = event.target;
    if (input.tagName === "INPUT") {
      // Shipping method description
      if (input.dataset.description.length > 0) {
        this.shippingMethodDescriptionTarget.style.display = "block";
        this.shippingMethodDescriptionContentTarget.innerText =
          input.dataset.description;
      } else {
        this.shippingMethodDescriptionTarget.style.display = "none";
        this.shippingMethodDescriptionContentTarget.innerText = null;
      }
      // Require a ship address
      if (
        input.dataset.requireaddress === "true" &&
        !this.shippingAddressCheckboxTarget.checked
      ) {
        this.shippingMethodAddressTarget.style.display = "block";
      } else {
        this.shippingMethodAddressTarget.style.display = "none";
      }
    }
  }

  showHideShippingAddress() {
    if (this.shippingAddressCheckboxTarget.checked) {
      this.shippingMethodAddressTarget.style.display = "none";
    } else {
      this.shippingMethodAddressTarget.style.display = "block";
    }
  }
}
