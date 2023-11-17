import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    this.element.querySelectorAll("a").forEach(function (link) {
      link.target = "_blank";
    });
  }
}
