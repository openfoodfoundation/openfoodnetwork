import { Controller } from "stimulus";
import { renderStreamMessage } from "@hotwired/turbo";

// Add to cart widget of the product grid (AddToCartComponent).
//
// Quantity changes are saved to the cart with a debounce and only one
// request in flight at a time; changes made while saving are coalesced
// into a single follow-up request. The server responds with Turbo
// Streams re-rendering the cart sidebar (CartSidebarComponent).
//
// Dispatches "cart:updating" and "cart:settled" window events so the
// cart-sidebar controller can show the busy state while saving.
export default class extends Controller {
  static targets = [
    "addButton",
    "quantityButton",
    "quantity",
    "plusButton",
    "nbItemInCart",
    "stock",
  ];
  static values = {
    variantId: Number,
    variantOnHand: Number, // parses to the Infinity global when on demand
    lowStockDisplay: Boolean,
    url: String,
    debounce: { type: Number, default: 1000 },
  };

  initialize() {
    this.saving = false;
    this.queued = false;
    this.dirty = false;
  }

  connect() {
    this.lastQuantity = this.quantity;
    this.render();
  }

  disconnect() {
    clearTimeout(this.saveTimeout);
  }

  addEmpty() {
    this.updateQuantity(1);
  }

  add() {
    this.updateQuantity(this.quantity + 1);
  }

  remove() {
    this.updateQuantity(this.quantity - 1);
  }

  manual() {
    const value = parseInt(this.quantityTarget.value, 10);
    if (isNaN(value)) return; // wait until a number is entered

    this.updateQuantity(value);
  }

  // private

  get quantity() {
    return parseInt(this.quantityTarget.value, 10) || 0;
  }

  updateQuantity(quantity) {
    const clamped = Math.max(0, Math.min(quantity, this.variantOnHandValue));
    this.quantityTarget.value = clamped;

    if (clamped === this.lastQuantity) return;

    this.lastQuantity = clamped;
    this.render();
    this.scheduleSave();
  }

  render() {
    const quantity = this.quantity;

    if (quantity > 0) {
      this.addButtonTarget.style.display = "none";
      this.quantityButtonTarget.style.display = "flex";
    } else {
      this.addButtonTarget.style.display = "block";
      this.quantityButtonTarget.style.display = "none";
    }

    // disable button when we reach the stock on hand
    this.plusButtonTarget.disabled = quantity >= this.variantOnHandValue;

    this.nbItemInCartTarget.textContent = I18n.t("js.shopfront.variant.quantity_in_cart", {
      quantity: quantity,
    });
    this.nbItemInCartTarget.style.visibility = quantity > 0 ? "visible" : "hidden";

    // display low stock if enabled and stock less than 3
    const showStock = quantity === 0 && this.lowStockDisplayValue && this.variantOnHandValue <= 3;
    this.stockTarget.style.display = showStock ? "block" : "none";
  }

  scheduleSave() {
    this.setDirty();
    clearTimeout(this.saveTimeout);
    this.saveTimeout = setTimeout(() => this.save(), this.debounceValue);
  }

  async save() {
    if (this.saving) {
      this.queued = true;
      return;
    }
    this.saving = true;

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        credentials: "same-origin",
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        },
        body: JSON.stringify({ quantity: this.quantity }),
      });
      renderStreamMessage(await response.text());
    } catch (error) {
      console.error("Failed to update the cart", error);
    } finally {
      this.saving = false;
      if (this.queued) {
        this.queued = false;
        this.save();
      } else {
        this.setSettled();
      }
    }
  }

  setDirty() {
    if (this.dirty) return;

    this.dirty = true;
    this.dispatch("updating", { prefix: "cart", detail: { variantId: this.variantIdValue } });
  }

  setSettled() {
    this.dirty = false;
    this.dispatch("settled", { prefix: "cart", detail: { variantId: this.variantIdValue } });
  }
}
