import { Controller } from "stimulus";

export default class extends Controller {
  static targets = [
    "addButton",
    "quantityButton",
    "quantity",
    "minusButton",
    "nbItemInCart",
    "stock",
  ];
  static values = {
    variantId: Number,
    variantOnHand: Number,
    lowStockDisplay: Boolean,
  };

  connect() {
    let quantity = parseInt(this.quantityTarget.value);

    if (quantity > 0) {
      this.#showQuantityButtons();
      this.#showItemInCart();
    } else {
      this.#showStock();
    }
  }

  addEmpty() {
    this.#dispatchCartUpdate(1);

    this.#showQuantityButtons();
    this.quantityTarget.value = 1;

    this.#showAndUpdateItemInCart(1);
  }

  add() {
    let quantity = parseInt(this.quantityTarget.value);
    quantity = quantity + 1;
    this.quantityTarget.value = quantity;

    this.#dispatchCartUpdate(quantity);

    this.#showAndUpdateItemInCart(quantity);
  }

  remove() {
    let quantity = parseInt(this.quantityTarget.value);
    quantity = Math.max(0, quantity - 1);
    this.quantityTarget.value = quantity;

    this.#dispatchCartUpdate(quantity);

    this.#showAndUpdateItemInCart(quantity);

    if (quantity === 0) {
      this.#hideQuantityButtons();
      this.#hideItemInCart();
      this.#showStock();
    }
  }

  manual(e) {
    const quantity = parseInt(this.quantityTarget.value);

    // check it's a number or a negative value
    if (isNaN(quantity) || quantity < 0) {
      return;
    }

    this.#dispatchCartUpdate(quantity);
    this.#showAndUpdateItemInCart(quantity);

    if (quantity === 0) {
      this.#hideQuantityButtons();
      this.nbItemInCartTarget.style.visibility = "hidden";
      this.#showStock();
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

  #showAndUpdateItemInCart(quantity = 0) {
    this.nbItemInCartTarget.textContent = I18n.t("js.shopfront.variant.quantity_in_cart", {
      quantity: quantity,
    });
    this.#showItemInCart();
    this.#hideStock();
  }

  #showItemInCart() {
    this.nbItemInCartTarget.style.visibility = "visible";
  }

  #hideItemInCart() {
    this.nbItemInCartTarget.style.visibility = "hidden";
  }

  #hideStock() {
    this.stockTarget.style.display = "none";
  }

  // display low stock if enabled and stock less than 3
  #showStock() {
    if (this.lowStockDisplayValue === true && this.variantOnHandValue <= 3) {
      this.stockTarget.style.display = "block";
    }
  }
}
