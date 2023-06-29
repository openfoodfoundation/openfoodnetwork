import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    // Fetch the products on page load
    this.fetch();
  }

  fetch = (event = {}) => {
    if (event && event.target) {
      this.stimulate("Products#fetch", event.target);
      return;
    }
    this.stimulate("Products#fetch");
  };

  changePerPage = (event) => {
    this.stimulate("Products#change_per_page", event.target);
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
