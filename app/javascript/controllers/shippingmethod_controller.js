import { Controller } from "stimulus";
export default class extends Controller {
  static targets = [
    "shippingMethodDescription",
    "shippingMethodAddress",
    "shippingAddressCheckbox",
  ];
  connect() {}

  selectShippingMethod(event) {
    const input = event.target;
    if (input.tagName === "INPUT") {
      // -- Shipping method description
      // Hide all shipping method descriptions
      this.shippingMethodDescriptionTargets.forEach((t) => {
        t.style.display = "none";
      });
      // but not the one we want ie. the one that matches the shipping method id
      this.shippingMethodDescriptionTargets.find(
        (e) => e.dataset["shippingmethodid"] == input.value
      ).style.display = "block";
      // -- Require a ship address
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
