import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    const input = this.element.querySelector("input");
    input.addEventListener("focus", this.focus.bind(this));
    input.addEventListener("blur", this.blur.bind(this));
    if (input.value.length > 0) {
      this.focus();
    }

    const label = this.element.querySelector("label");
    // Add transition class to the label and display the label
    // after a short delay to avoid flickering
    setTimeout(() => {
      label.classList.add("with-transition");
      label.style.display = "block";
    }, 100);
  }

  focus() {
    this.element.classList.add("active");
  }

  blur(e) {
    if (e.target.value.length === 0) {
      this.element.classList.remove("active");
    }
  }
}
