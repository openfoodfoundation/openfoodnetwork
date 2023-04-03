import { Controller } from "stimulus";

export default class extends Controller {
  static values = { target: String };

  open() {
    let modal = document.getElementById(this.targetValue);
    let modalController = this.application.getControllerForElementAndIdentifier(
      modal,
      this.getIdentifier()
    );
    modalController.open();
  }

  getIdentifier() {
    return "modal";
  }
}
