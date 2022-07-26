import { Controller } from "stimulus";

export default class extends Controller {
  static values = { target: String };

  open() {
    let helpModal = document.getElementById(this.targetValue);
    let helpModalController =
      this.application.getControllerForElementAndIdentifier(
        helpModal,
        "help-modal"
      );
    helpModalController.open();
  }
}
