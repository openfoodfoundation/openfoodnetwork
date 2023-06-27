import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    document.addEventListener("show-loading", this.showLoading);
    document.addEventListener("hide-loading", this.hideLoading);
  }

  disconnect() {
    document.removeEventListener("show-loading", this.showLoading);
    document.removeEventListener("hide-loading", this.hideLoading);
  }

  hideLoading = () => {
    this.element.classList.add("hidden");
  };

  showLoading = () => {
    this.element.classList.remove("hidden");
  };
}
