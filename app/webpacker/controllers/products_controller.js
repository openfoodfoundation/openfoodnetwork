import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    // Fetch the products on page load
    this.stimulate("Products#fetch");
  }

  beforeReflex() {
    this.showLoading();
  }

  afterReflex() {
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
