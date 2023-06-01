import { Controller } from "stimulus";
import { useOpenAndCloseAsAModal } from "./mixins/useOpenAndCloseAsAModal";

export default class extends Controller {
  static targets = ["background", "modal"];
  static values = { instant: { type: Boolean, default: false } }

  connect() {
    useOpenAndCloseAsAModal(this);
    window.addEventListener("modal:close", this.close.bind(this));

    if (this.instantValue) { this.open() }
  }

  disconnect() {
    window.removeEventListener("modal:close", this.close);
  }

  remove(event) {
    this.close(event, true)
  }
}
