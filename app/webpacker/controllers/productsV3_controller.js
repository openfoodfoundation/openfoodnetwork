import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["loading"];

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

  hideLoading = () => {
    this.loadingTarget.classList.add("hidden");
  };

  showLoading = () => {
    this.loadingTarget.classList.remove("hidden");
  };

  beforeFetch(element, reflex, noop, reflexId) {
    this.showLoading();
  }

  afterFetch(element, reflex, noop, reflexId) {
    this.hideLoading();
  }
}
