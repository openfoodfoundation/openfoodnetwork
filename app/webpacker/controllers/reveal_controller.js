import ApplicationController from "./application_controller";
export default class extends ApplicationController {
  static targets = ["item"];
  static classes = ["hidden"];
  static values = {
    selector: String,
  };

  connect() {
    this.class = this.hasHiddenClass ? this.hiddenClass : "hidden";
    this.items = [];
    if (this.hasSelectorValue) {
      this.items = Array.from(document.querySelectorAll(this.selectorValue));
    }
  }

  toggle() {
    this.itemTargets.forEach((item) => {
      item.classList.toggle(this.class);
    });

    this.items.forEach((item) => {
      item.classList.toggle(this.class);
    });
  }
}
