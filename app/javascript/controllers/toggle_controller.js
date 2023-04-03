import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["content"];

  toggle(event) {
    const input = event.currentTarget;
    this.contentTargets.forEach((t) => {
      t.style.display = input.dataset.toggleShow === "true" ? "block" : "none";
    });
  }
}
