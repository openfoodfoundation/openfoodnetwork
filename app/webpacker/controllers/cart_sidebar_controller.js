import { Controller } from "stimulus";

// Opens and closes the server-rendered cart sidebar (CartSidebarComponent)
// and keeps the cart icons in the menu up to date.
//
// The controller lives on the menu wrapper so the sidebar target can be
// replaced by Turbo Streams without losing the open state.
export default class extends Controller {
  static targets = ["sidebar", "icon", "counter"];
  static values = { open: Boolean };

  sidebarTargetConnected(sidebar) {
    sidebar.classList.toggle("shown", this.openValue);
    this.updateIcons(sidebar);
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

  updateIcons(sidebar) {
    const count = parseInt(sidebar.dataset.itemCount || "0", 10);

    this.counterTargets.forEach((counter) => {
      counter.textContent = count;
    });
    this.iconTargets.forEach((icon) => {
      icon.classList.toggle("dirty", count === 0);
    });
  }
}
