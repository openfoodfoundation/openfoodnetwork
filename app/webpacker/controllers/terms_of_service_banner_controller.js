import { Controller } from "stimulus";

export default class extends Controller {
  static values = { url: String };

  accept() {
    const token = document.querySelector('meta[name="csrf-token"]').content;
    // We don't really care if the update fails, if it fails it will result in the banner still
    // being shown.
    fetch(this.urlValue, { method: "post", headers: { "X-CSRF-Token": token } });
  }

  close_banner() {
    this.element.remove();
  }
}
