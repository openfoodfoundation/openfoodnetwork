import { Controller } from "stimulus";

document.addEventListener("turbolinks:before-cache", () =>
  document.getElementById("flash").remove()
);

export default class extends Controller {
  static values = {
    autoClose: Boolean,
  };

  connect() {
    if (this.autoCloseValue) {
      setTimeout(this.close.bind(this), 5000);
    }
  }

  close(e) {
    // Fade out
    this.element.classList.remove("animate-show");
    this.element.classList.add("animate-hide-500");
    setTimeout(this.remove.bind(this), 500);
    e && e.preventDefault(); // Prevent submitting if we're inside a form
  }

  remove() {
    this.element.remove();
  }
}
