import { Controller } from "stimulus";
const NOTIFICATION_TIME = 5000; // 5 seconds
const HIDE_CLASS = "hidden";

export default class extends Controller {
  static targets = ["loading", "loaded", "link"];

  connect() {
    this.setTimeout();
  }

  disconnect() {
    this.clearTimeout();
  }

  checkFile() {
    if (!this.hasLoadedTarget || !this.loadedTarget.classList.contains(HIDE_CLASS)) {
      // If link already loaded successfully, we don't need to check anymore.
      return;
    }

    const response = fetch(this.linkTarget.href).then((response) => {
      if (response.status == 200) {
        this.loadingTarget.classList.add(HIDE_CLASS);
        this.loadedTarget.classList.remove(HIDE_CLASS);
      } else {
        this.setTimeout();
      }
    });
  }

  setTimeout() {
    this.timeout = setTimeout(this.checkFile.bind(this), NOTIFICATION_TIME);
  }
  clearTimeout() {
    clearTimeout(this.timeout);
  }
}
