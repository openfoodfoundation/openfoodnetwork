import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["loading"];

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
    if (this.getLoadingController()) {
      this.getLoadingController().showLoading();
    }
  };

  hideLoading = () => {
    if (this.getLoadingController()) {
      this.getLoadingController().hideLoading();
    }
  };

  getLoadingController = () => {
    return (this.loadongController = this.application.getControllerForElementAndIdentifier(
      this.loadingTarget,
      "loading"
    ));
  };
}
