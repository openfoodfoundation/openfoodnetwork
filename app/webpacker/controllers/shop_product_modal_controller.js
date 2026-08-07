import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    url: String,
  };

  async open(event) {
    event.preventDefault();

    if (!this.hasUrlValue) return;

    await this.load(this.urlValue);
  }

  async load(url) {
    if (!url) return;

    const container = document.getElementById("shop-product-modal-container");
    if (!container) return;

    this.abortPendingRequest();
    this.abortController = new AbortController();

    window.dispatchEvent(new Event("modal:close"));

    try {
      const response = await fetch(url, {
        method: "GET",
        headers: {
          Accept: "text/html",
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin",
        signal: this.abortController.signal,
      });

      if (!response.ok) return;

      container.innerHTML = await response.text();
    } catch (error) {
      if (error.name !== "AbortError") {
        throw error;
      }
    }
  }

  disconnect() {
    this.abortPendingRequest();
  }

  abortPendingRequest() {
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
  }
}
