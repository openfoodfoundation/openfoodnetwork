import { Controller } from "stimulus";

document.addEventListener("turbolinks:before-cache", () =>
  document.getElementById("flash").remove()
);

export default class extends Controller {
  close() {
    this.element.remove();
  }
}
