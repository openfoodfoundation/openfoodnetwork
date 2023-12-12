import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["loading"];
  static values = {currentId: Number};

  connect() {
    super.connect();
    // Fetch the products on page load
    this.stimulate("Products#fetch");
  }

  deleteProduct() {
    window.dispatchEvent(new Event('modal:close'));
    this.stimulate('Products#delete_product', this.currentIdValue)
  }

  deleteVariant() {
    this.stimulate('Products#delete_variant', this.currentIdValue)
  }

  beforeReflex() {
    this.showLoading();
    this.scrollToElement();
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

  scrollToElement = () => {
    this.element.scrollIntoView();
  };

  getLoadingController = () => {
    let loadingSpinner = null;
    try {
      loadingSpinner = this.loadingTarget; // throws missing loading target error
    } catch (error) {
      loadingSpinner = document.getElementById('loading-spinner');
    }

    return (this.loadingController ||= this.application.getControllerForElementAndIdentifier(
      loadingSpinner,
      "loading"
    ));
  };
}
