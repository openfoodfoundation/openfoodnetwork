import { Controller } from "stimulus";
import { useOpenAndCloseAsAModal } from "./mixins/useOpenAndCloseAsAModal";

export default class extends Controller {
  static targets = ["background", "modal"];

  connect() {
    useOpenAndCloseAsAModal(this);
  }
}
