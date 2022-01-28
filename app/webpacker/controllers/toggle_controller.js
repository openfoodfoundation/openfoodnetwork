import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["content"];

  toggle(event) {
    event.stopImmediatePropagation()
    const input = event.currentTarget;
    const chevron = input.querySelector(".icon-chevron-down, .icon-chevron-up")
    const toggleViaSingleElement = !input.dataset.toggleShow;

    if(chevron) {
      chevron.classList.toggle("icon-chevron-down");
      chevron.classList.toggle("icon-chevron-up");
    }

    this.contentTargets.forEach((t) => {
      if(toggleViaSingleElement) {
        t.style.display = t.style.display === "none" ? "block" : "none";
      } else {
        t.style.display = input.dataset.toggleShow === "true" ? "block" : "none";
      }
    });
  }
}
