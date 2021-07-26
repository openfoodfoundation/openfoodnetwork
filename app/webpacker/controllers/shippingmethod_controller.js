import { Controller } from "stimulus";
export default class extends Controller {
  static targets = [
    "shippingMethodDescription",
    "shippingMethodDescriptionContent",
  ];
  connect() {
    // Hide shippingMethodDescription by default
    this.shippingMethodDescriptionTarget.style.display = "none";
  }
  selectShippingMethod(event) {
    const input = event.target;
    if (input.tagName === "INPUT") {
      if (input.dataset.description.length > 0) {
        this.shippingMethodDescriptionTarget.style.display = "block";
        this.shippingMethodDescriptionContentTarget.innerText =
          input.dataset.description;
      } else {
        this.shippingMethodDescriptionTarget.style.display = "none";
        this.shippingMethodDescriptionContentTarget.innerText = null;
      }
    }
  }
}
