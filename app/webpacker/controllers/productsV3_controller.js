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

  changePerPage = (event) => {
    this.stimulate("ProductsV3#change_per_page", event.target);
  };

  beforeChangePerPage() {
    this.showLoading();
  }

  afterChangePerPage() {
    this.hideLoading();
  }

  beforeFetch() {
    this.showLoading();
  }

  afterFetch() {
    this.hideLoading();
  }

  showLoading = () => {
    const event = new CustomEvent("show-loading");
    document.dispatchEvent(event);
  };

  hideLoading = () => {
    const event = new CustomEvent("hide-loading");
    document.dispatchEvent(event);
  };
}
