import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    document.addEventListener(
      "stimulus-reflex:before",
      this.handleBeforeReflex.bind(this)
    );
    document.addEventListener(
      "stimulus-reflex:after",
      this.handleAfterReflex.bind(this)
    );
  }

  disconnect() {
    super.disconnect();
    document.removeEventListener(
      "stimulus-reflex:before",
      this.handleBeforeReflex.bind(this)
    );
    document.removeEventListener(
      "stimulus-reflex:after",
      this.handleAfterReflex.bind(this)
    );
  }

  handleBeforeReflex(event) {
    if (event.detail.reflex.indexOf("ProductsTableComponent#") !== -1) {
      this.showLoading();
    }
  }

  handleAfterReflex(event) {
    if (event.detail.reflex.indexOf("ProductsTableComponent#") !== -1) {
      this.hideLoading();
    }
  }

  showLoading() {
    this.element.classList.add("loading");
  }
  hideLoading() {
    this.element.classList.remove("loading");
  }
}
