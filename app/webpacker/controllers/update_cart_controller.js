import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["addButton", "quantityButton", "quantity", "minusButton"];
  static values = { variantId: Number };

  // TODO display number in cart
  connect() {
    let quantity = parseInt(this.quantityTarget.value);

    if (quantity > 0) {
      this.#showQuantityButtons();
    }
  }

  addEmpty() {
    this.#dispatchCartUpdate(1);

    this.#showQuantityButtons();
    this.quantityTarget.value = 1;
  }

  add() {
    let quantity = parseInt(this.quantityTarget.value);
    quantity = quantity + 1;
    this.quantityTarget.value = quantity;

    this.#dispatchCartUpdate(quantity);
  }

  remove() {
    let quantity = parseInt(this.quantityTarget.value);
    quantity = Math.max(0, quantity - 1);
    this.quantityTarget.value = quantity;

    this.#dispatchCartUpdate(quantity);

    if (quantity === 0) {
      this.#hideQuantityButtons();
    }
  }

  manual(e) {
    const quantity = parseInt(this.quantityTarget.value);

    // check it's a number or a negative value
    if (isNaN(quantity) || quantity < 0) {
      return;
    }

    this.#dispatchCartUpdate(quantity);

    if (quantity === 0) {
      this.#hideQuantityButtons();
    }
  }

  // private

  #showQuantityButtons() {
    this.addButtonTarget.style.display = "none";
    this.quantityButtonTarget.style.display = "block";
  }

  #hideQuantityButtons() {
    this.addButtonTarget.style.display = "block";
    this.quantityButtonTarget.style.display = "none";
  }

  #dispatchCartUpdate(quantity) {
    const ev = new CustomEvent("updateCart", {
      detail: { variant: { id: this.variantIdValue }, quantity: quantity },
    });
    window.dispatchEvent(ev);
  }
}
