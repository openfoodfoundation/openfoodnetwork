import { Controller } from "stimulus";

export default class extends Controller {
  static values = { target: String, modalDataset: Object };

  open() {
    let modal = document.getElementById(this.targetValue);
    let modalController = this.application.getControllerForElementAndIdentifier(
      modal,
      this.getIdentifier(),
    );
    modalController.open();
  }

  setModalDataSetOnConfirm(event) {
    try {
      const modalId = this.targetValue;
      const moodalConfirmButtonQuery = `#${modalId} #modal-confirm-button`;
      const confirmButton = document.querySelector(moodalConfirmButtonQuery);
      Object.keys(this.modalDatasetValue).forEach((datasetKey) => {
        confirmButton.setAttribute(datasetKey, this.modalDatasetValue[datasetKey]);
      });
    } catch (e) {
      // In case of any type of error in setting the dataset value, stop the further actions i.e. opening the modal
      event.stopImmediatePropagation();
      throw e;
    }
  }

  getIdentifier() {
    return "modal";
  }
}
