import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["element", "background"];

  select() {
    this.backgroundTarget.style.display = "block";
    this.elementTarget.style.display = "block";

    setTimeout(() => {
      this.elementTarget.classList.add("in");
      this.backgroundTarget.classList.add("in");
    });
  }

  close() {
    this.elementTarget.style.display = "none";
    this.backgroundTarget.style.display = "none";

    setTimeout(() => {
      this.elementTarget.classList.remove("in");
      this.backgroundTarget.classList.remove("in");
    });
  }

  closeIfEscapeKey(e) {
    if (e.code == "Escape") {
      this.close();
    }
  }
}
