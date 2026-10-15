import { Controller } from "stimulus";
import { renderStreamMessage } from "@hotwired/turbo";
import showHttpError from "js/services/show_http_error";

// Add to cart widget of the product grid (AddToCartComponent).
//
// Quantity changes are saved to the cart with a debounce and only one
// request in flight at a time; changes made while saving are coalesced
// into a single follow-up request. The server responds with Turbo
// Streams re-rendering the cart sidebar (CartSidebarComponent).
//
// Group buy variants (groupBuyValue) show a second, labelled stepper for
// max_quantity instead of the "N in cart" / remaining stock elements, which
// group buy widgets don't render at all. Min and max are kept in the
// legacy invariant: min <= max <= stock on hand, and raising min above max
// pulls max up with it.
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
    "maxQuantityButton",
    "maxQuantity",
    "maxPlusButton",
    "maxMinusButton",
  ];
  static values = {
    variantId: Number,
    variantOnHand: Number, // parses to the Infinity global when on demand
    lowStockDisplay: Boolean,
    groupBuy: Boolean,
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
    if (this.groupBuyValue) this.lastMaxQuantity = this.maxQuantity;
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

  addMax() {
    this.updateMaxQuantity(this.maxQuantity + 1);
  }

  removeMax() {
    this.updateMaxQuantity(this.maxQuantity - 1);
  }

  manualMax() {
    const value = parseInt(this.maxQuantityTarget.value, 10);
    if (isNaN(value)) return; // wait until a number is entered

    this.updateMaxQuantity(value);
  }

  // private

  get quantity() {
    return parseInt(this.quantityTarget.value, 10) || 0;
  }

  get maxQuantity() {
    return parseInt(this.maxQuantityTarget.value, 10) || 0;
  }

  updateQuantity(quantity) {
    const clamped = Math.max(0, Math.min(quantity, this.variantOnHandValue));
    this.quantityTarget.value = clamped;

    if (this.groupBuyValue) this.keepMaxAboveQuantity(clamped);

    if (clamped === this.lastQuantity) return;

    this.lastQuantity = clamped;
    this.render();
    this.scheduleSave();
  }

  // Group buy invariant: max is never below min. Raising min above max pulls max up with
  // it, and dropping min to 0 resets max too, so re-adding starts fresh at 1/1.
  keepMaxAboveQuantity(quantity) {
    if (quantity === 0) {
      this.maxQuantityTarget.value = 0;
      this.lastMaxQuantity = 0;
    } else if (this.maxQuantity < quantity) {
      this.maxQuantityTarget.value = quantity;
      this.lastMaxQuantity = quantity;
    }
  }

  updateMaxQuantity(quantity) {
    const clamped = Math.max(this.quantity, Math.min(quantity, this.variantOnHandValue));
    this.maxQuantityTarget.value = clamped;

    if (clamped === this.lastMaxQuantity) return;

    this.lastMaxQuantity = clamped;
    this.render();
    this.scheduleSave();
  }

  render() {
    const quantity = this.quantity;

    if (quantity > 0) {
      this.addButtonTarget.style.display = "none";
      this.quantityButtonTarget.style.display = "flex";
      if (this.groupBuyValue) this.maxQuantityButtonTarget.style.display = "flex";
    } else {
      this.addButtonTarget.style.display = "block";
      this.quantityButtonTarget.style.display = "none";
      if (this.groupBuyValue) this.maxQuantityButtonTarget.style.display = "none";
    }

    // disable button when we reach the stock on hand
    this.plusButtonTarget.disabled = quantity >= this.variantOnHandValue;

    if (this.groupBuyValue) {
      const maxQuantity = this.maxQuantity;
      this.maxMinusButtonTarget.disabled = maxQuantity <= quantity;
      this.maxPlusButtonTarget.disabled = maxQuantity >= this.variantOnHandValue;
      return;
    }

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
      const body = { quantity: this.quantity };
      if (this.groupBuyValue) body.max_quantity = this.maxQuantity;

      const response = await fetch(this.urlValue, {
        method: "PATCH",
        credentials: "same-origin",
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        },
        body: JSON.stringify(body),
      });
      if (response.ok || response.status === 422) {
        // Validation errors (422) come as Turbo Streams with a flash message.
        renderStreamMessage(await response.text());
      } else {
        showHttpError(response.status);
      }
    } catch {
      // A network error; showHttpError alerts about it when passed no status.
      showHttpError();
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
