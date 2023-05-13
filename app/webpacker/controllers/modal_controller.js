import { Controller } from "stimulus";
import { useOpenAndCloseAsAModal } from "./mixins/useOpenAndCloseAsAModal";

export default class extends Controller {
  static targets = ["background", "modal"];

  connect() {
    useOpenAndCloseAsAModal(this);
    window.addEventListener("modal:open", this.open.bind(this));
    window.addEventListener("modal:close", this.close.bind(this));
  }

  disconnect() {
    window.removeEventListener("modal:open", this.open);
    window.removeEventListener("modal:close", this.close);
  }
}
