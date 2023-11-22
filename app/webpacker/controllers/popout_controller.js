import { Controller } from "stimulus";

// Allows a form section to "pop out" and show additional options
export default class PopoutController extends Controller {
  static targets = ["button", "dialog"];

  connect() {
    this.first_input = this.dialogTarget.querySelector("input");

    // Show when click or down-arrow on button
    this.buttonTarget.addEventListener("click", this.show.bind(this));
    this.buttonTarget.addEventListener("keydown", this.showIfDownArrow.bind(this));
  }

  show(e) {
    this.dialogTarget.style.display = "block";
    this.first_input.focus();
    e.preventDefault();
  }

  showIfDownArrow(e) {
    if (e.keyCode == 40) {
      this.show(e);
    }
  }
}
