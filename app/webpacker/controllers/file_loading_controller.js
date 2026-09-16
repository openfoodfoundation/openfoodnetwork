import { Controller } from "stimulus";
const INITIAL_POLL_INTERVAL = 1000; // 1 second
const MAX_POLL_INTERVAL = 5000; // 5 seconds
const HIDE_CLASS = "hidden";

export default class extends Controller {
  static targets = ["loading", "loaded", "link"];

  connect() {
    this.pollInterval = INITIAL_POLL_INTERVAL;
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
        if (this.hasLoadingTarget) {
          this.loadingTarget.classList.add(HIDE_CLASS);
        }
        this.loadedTarget.classList.remove(HIDE_CLASS);
      } else {
        // Poll quickly at first (most jobs finish in well under a second), then back off.
        this.pollInterval = Math.min(this.pollInterval * 2, MAX_POLL_INTERVAL);
        this.setTimeout();
      }
    });
  }

  setTimeout() {
    this.timeout = setTimeout(this.checkFile.bind(this), this.pollInterval);
  }
  clearTimeout() {
    clearTimeout(this.timeout);
  }
}
