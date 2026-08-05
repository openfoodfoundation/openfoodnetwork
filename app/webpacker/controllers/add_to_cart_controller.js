import { Controller } from "stimulus";
import { renderStreamMessage } from "@hotwired/turbo";

// Quantity widget of the Turbo cart (AddToCartComponent).
//
// Quantity changes are saved with a debounce and only one request in
// flight at a time; changes made while saving are coalesced into a
// single follow-up request. The server responds with Turbo Streams
// re-rendering the cart sidebar.
//
// Dispatches "cart:updating" and "cart:settled" window events so the
// cart-sidebar controller can show the busy state.
export default class extends Controller {
  static targets = [
    "addGroup",
    "controls",
    "input",
    "maxInput",
    "bulkQuantity",
    "bulkMax",
    "display",
    "remainingStock",
  ];
  static values = {
    variantId: Number,
    quantity: Number,
    maxQuantity: Number,
    groupBuy: Boolean,
    onHand: Number,
    onDemand: Boolean,
    debounce: { type: Number, default: 1000 },
  };

  initialize() {
    this.saving = false;
    this.queued = false;
    this.dirty = false;
  }

  disconnect() {
    clearTimeout(this.saveTimeout);
  }

  add() {
    this.updateQuantity(1);
  }

  // Group buy: the Add button also opens the bulk buy modal (modal-link).
  addBulk() {
    if (this.quantityValue === 0) this.updateQuantity(1);
  }

  increment() {
    this.updateQuantity(this.quantityValue + 1);
  }

  decrement() {
    this.updateQuantity(this.quantityValue - 1);
  }

  incrementMax() {
    this.updateMaxQuantity(this.maxQuantityValue + 1);
  }

  decrementMax() {
    this.updateMaxQuantity(this.maxQuantityValue - 1);
  }

  inputChanged() {
    const value = parseInt(this.inputTarget.value, 10);
    if (isNaN(value)) return; // wait until a number is entered

    this.updateQuantity(value, { fromInput: true });
  }

  maxInputChanged() {
    const value = parseInt(this.maxInputTarget.value, 10);
    if (isNaN(value)) return; // wait until a number is entered

    this.updateMaxQuantity(value, { fromInput: true });
  }

  // Submitting the form (eg. pressing enter in the input) saves right away.
  submit(event) {
    event.preventDefault();
    clearTimeout(this.saveTimeout);
    this.save();
  }

  updateQuantity(quantity, { fromInput = false } = {}) {
    const clamped = this.clamp(quantity);

    if (fromInput && clamped !== quantity) {
      this.inputTarget.value = clamped;
    }
    if (clamped === this.quantityValue) return;

    this.quantityValue = clamped;
    // A group buy maximum can't be below the wanted quantity.
    if (this.groupBuyValue && (clamped < 1 || this.maxQuantityValue < clamped)) {
      this.maxQuantityValue = clamped;
    }
    this.render();
    this.scheduleSave();
  }

  updateMaxQuantity(maxQuantity, { fromInput = false } = {}) {
    const clamped = this.clamp(maxQuantity);

    if (fromInput && clamped !== maxQuantity) {
      this.maxInputTarget.value = clamped;
    }
    if (clamped === this.maxQuantityValue) return;

    this.maxQuantityValue = clamped;
    // Lowering the maximum below the wanted quantity lowers the quantity.
    if (clamped < this.quantityValue) {
      this.quantityValue = clamped;
    }
    this.render();
    this.scheduleSave();
  }

  clamp(quantity) {
    let clamped = Math.max(quantity, 0);
    if (!this.onDemandValue) {
      clamped = Math.min(clamped, this.onHandValue);
    }
    return clamped;
  }

  render() {
    const quantity = this.quantityValue;

    if (parseInt(this.inputTarget.value, 10) !== quantity) {
      this.inputTarget.value = quantity;
    }
    this.addGroupTarget.style.display = quantity > 0 ? "none" : "";
    this.controlsTarget.style.display = quantity > 0 ? "" : "none";
    if (this.hasRemainingStockTarget) {
      this.remainingStockTarget.style.display = quantity > 0 ? "none" : "";
    }
    this.displayTarget.classList.toggle("visible", quantity > 0);
    if (!this.groupBuyValue) {
      this.displayTarget.textContent = I18n.t("js.shopfront.variant.quantity_in_cart", {
        quantity,
      });
    }
    if (
      this.hasMaxInputTarget &&
      parseInt(this.maxInputTarget.value, 10) !== this.maxQuantityValue
    ) {
      this.maxInputTarget.value = this.maxQuantityValue;
    }
    if (this.hasBulkQuantityTarget) {
      this.bulkQuantityTarget.textContent = quantity;
    }
    if (this.hasBulkMaxTarget) {
      this.bulkMaxTarget.textContent = this.maxQuantityValue > 0 ? this.maxQuantityValue : "-";
    }
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
      const response = await fetch(this.element.action, {
        method: "PATCH",
        credentials: "same-origin",
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        },
        body: JSON.stringify(this.payload()),
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

  payload() {
    if (this.groupBuyValue) {
      return { quantity: this.quantityValue, max_quantity: this.maxQuantityValue };
    }
    return { quantity: this.quantityValue };
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
