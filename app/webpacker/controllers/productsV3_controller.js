import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    // Fetch the products on page load
    this.fetch();
  }

  fetch = (event = {}) => {
    if (event && event.target) {
      this.stimulate("ProductsV3#fetch", event.target);
      return;
    }
    this.stimulate("ProductsV3#fetch");
  };

  beforeFetch(element, reflex, noop, reflexId) {
    const event = new CustomEvent("show-loading");
    document.dispatchEvent(event);
  }

  afterFetch(element, reflex, noop, reflexId) {
    const event = new CustomEvent("hide-loading");
    document.dispatchEvent(event);
  }
}
