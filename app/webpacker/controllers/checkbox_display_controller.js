import { Controller } from "stimulus";

export default class extends Controller {
  static values = { targetId: String };

  connect() {
    this.element.addEventListener("change", this.change.bind(this));
    if (this.element.checked) {
      this.showTarget();
    } else {
      this.hideTarget();
    }
  }

  disconnect() {
    this.element.removeEventListener("change", this.change.bind(this));
  }

  change(event) {
    // if the checkbox is checked, display the target
    if (this.element.checked) {
      this.showTarget();
    } else {
      this.hideTarget();
    }
  }

  showTarget() {
    let target = document.getElementById(this.targetIdValue);
    target.style.display = "block";
  }

  hideTarget() {
    let target = document.getElementById(this.targetIdValue);
    target.style.display = "none";
  }
}
