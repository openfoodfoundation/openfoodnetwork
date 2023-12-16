import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["loading"];
  static values = { currentId: Number };

  connect() {
    super.connect();
    // Fetch the products on page load
    this.stimulate("Products#fetch");
  }

  beforeReflex(element) {
    // To prevent the double click on the confirm modal's confirmation button
    if (element.id === "confirmModalButton") {
      window.dispatchEvent(new Event("modal:close"));
    }
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
    return (this.loadingController ||= this.application.getControllerForElementAndIdentifier(
      this.loadingTarget,
      "loading"
    ));
  };
}
