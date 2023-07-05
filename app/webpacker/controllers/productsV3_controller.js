import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["loading"];

  connect() {
    super.connect();
    // Fetch the products on page load
    this.load();
  }

  load = () => {
    this.showLoading();
    this.stimulate("Admin::ProductsV3#fetch").then(() => this.hideLoading());
  };

  hideLoading = () => {
    this.loadingTarget.classList.add("hidden");
  };

  showLoading = () => {
    this.loadingTarget.classList.remove("hidden");
  };
}
