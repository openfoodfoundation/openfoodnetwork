import { Controller } from "stimulus";

// Opens and closes the server-rendered cart sidebar (CartSidebarComponent)
// and keeps the cart icons in the menu up to date.
//
// The controller lives on the menu wrapper so the sidebar target can be
// replaced by Turbo Streams without losing the open state. It also
// listens to the "cart:updating"/"cart:settled" window events of the
// add-to-cart widgets to show the busy state while changes are saved.
export default class extends Controller {
  static targets = ["sidebar", "icon", "counter", "editCartLabel"];
  static values = { open: Boolean };

  initialize() {
    this.pendingVariants = new Set();
  }

  sidebarTargetConnected(sidebar) {
    sidebar.classList.toggle("shown", this.openValue);
    this.updateIcons(sidebar);
    this.applyBusy();
  }

  toggle() {
    this.openValue = !this.openValue;
  }

  close() {
    this.openValue = false;
  }

  openValueChanged() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.toggle("shown", this.openValue);
    }
    // Lock the page scroll while the sidebar is open.
    document.body.style.overflow = this.openValue ? "hidden" : "";
  }

  cartUpdating(event) {
    this.pendingVariants.add(event.detail.variantId);
    this.applyBusy();
  }

  cartSettled(event) {
    this.pendingVariants.delete(event.detail.variantId);
    this.applyBusy();
  }

  updateIcons(sidebar) {
    const count = parseInt(sidebar.dataset.itemCount || "0", 10);

    this.counterTargets.forEach((counter) => {
      counter.textContent = count;
    });
    this.iconTargets.forEach((icon) => {
      icon.classList.toggle("dirty", count === 0 || this.busy);
    });
  }

  get busy() {
    return this.pendingVariants.size > 0;
  }

  // While busy, the edit cart and checkout buttons are disabled and the
  // edit cart button reads "Updating cart..." instead.
  applyBusy() {
    if (!this.hasSidebarTarget) return;
    const sidebar = this.sidebarTarget;

    sidebar.setAttribute("aria-busy", this.busy);
    sidebar.querySelectorAll(".sidebar-footer a.button").forEach((link) => {
      link.toggleAttribute("disabled", this.busy);
    });
    this.editCartLabelTargets.forEach((label) => {
      label.textContent = this.busy
        ? I18n.t("cart_updating")
        : I18n.t("shared.menu.cart_sidebar.edit_cart");
    });
    this.iconTargets.forEach((icon) => {
      icon.classList.toggle("pure-dirty", this.busy);
    });
  }
}
