import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["input"];

  update(event) {
    const value = event.currentTarget.dataset.updateinputValue;

    this.inputTargets.forEach((t) => {
      t.value = value;
    });
  }
}
