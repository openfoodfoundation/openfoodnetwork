import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    setTimeout(this.fadeout, 1500);
  }

  fadeout = () => {
    this.element.classList.add("animate-hide-500");
    setTimeout(this.remove, 500);
  };

  remove = () => {
    this.element.remove();
  };
}
