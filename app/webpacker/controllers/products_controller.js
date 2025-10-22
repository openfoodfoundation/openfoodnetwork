import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["loading"];
  static values = { currentId: Number };

  connect() {
    super.connect();
  }

  beforeReflex() {
    this.showLoading();
    this.scrollToElement();
  }

  afterReflex() {
    this.hideLoading();
  }

  delete_product() {
    this.#deleteByRecordType("product");
  }

  delete_variant() {
    this.#deleteByRecordType("variant");
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
      "loading",
    ));
  };

  // +recordType+ can either be 'product' or 'variant'
  #deleteByRecordType(recordType) {
    const deletePath = document
      .querySelector(`#${recordType}-delete-modal #modal-confirm-button`)
      .getAttribute("data-delete-path");
    const elementToBeRemoved = this.#getElementToBeRemoved(deletePath, recordType);

    const handleSlideOutAnimationEnd = async () => {
      // in case of test env, we won't be having csrf token
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");

      try {
        const response = await fetch(deletePath, {
          method: "DELETE",
          headers: {
            Accept: "text/vnd.turbo-stream.html",
            "X-CSRF-Token": csrfToken,
          },
        });
        // need to render the turboStream message, that's why not throwing error here
        if (response.status === 500) elementToBeRemoved.classList.remove("slide-out");

        const responseTurboStream = await response.text();
        Turbo.renderStreamMessage(responseTurboStream);
      } catch (error) {
        console.error(error.message);
        elementToBeRemoved.classList.remove("slide-out");
      } finally {
        elementToBeRemoved.removeEventListener("animationend", handleSlideOutAnimationEnd);
      }
    };

    // remove the clone animation before deleting
    elementToBeRemoved.classList.remove("slide-in");
    elementToBeRemoved.classList.add("slide-out");
    elementToBeRemoved.addEventListener("animationend", handleSlideOutAnimationEnd);
  }

  #getElementToBeRemoved(path, recordType) {
    const recordId = path.substring(path.lastIndexOf("/") + 1);
    const elementDomId = `${recordType}_${recordId}`;

    return document.getElementById(elementDomId);
  }
}
