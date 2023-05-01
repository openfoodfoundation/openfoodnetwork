import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["button"];

  connect() {
    // Hacky way to go arount mrjus automatically enabling/disabling form element
    setTimeout(() => {
      if (this.hasButtonTarget) {
        this.buttonTarget.disabled = true;
      }
    }, 100);
  }

  inputIsChanged(e) {
    if (e.target.value !== "") {
      this.buttonTarget.disabled = false;
    } else {
      this.buttonTarget.disabled = true;
    }
  }
}
