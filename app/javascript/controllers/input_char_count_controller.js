import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["count", "input"];

  connect() {
    this.inputTarget.addEventListener("keyup", this.countCharacters.bind(this));
    this.countCharacters();
  }

  countCharacters() {
    this.displayCount(
      this.inputTarget.value.length,
      this.inputTarget.maxLength
    );
  }

  displayCount(count, max) {
    this.countTarget.textContent = `${count}/${max}`;
  }
}
