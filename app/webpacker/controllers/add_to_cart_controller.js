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
  static targets = ["addGroup", "controls", "input", "display", "remainingStock"];
  static values = {
    variantId: Number,
    quantity: Number,
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

  increment() {
    this.updateQuantity(this.quantityValue + 1);
  }

  decrement() {
    this.updateQuantity(this.quantityValue - 1);
  }

  inputChanged() {
    const value = parseInt(this.inputTarget.value, 10);
    if (isNaN(value)) return; // wait until a number is entered

    this.updateQuantity(value, { fromInput: true });
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
    this.displayTarget.textContent = I18n.t("js.shopfront.variant.quantity_in_cart", {
      quantity,
    });
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
        body: JSON.stringify({ quantity: this.quantityValue }),
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
