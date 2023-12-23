import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static values = { id: Number };

  setDeleteModalDataSet(event) {
    try {
      const modalId = this.element.dataset.modalLinkTargetValue; // whether variant or product delete modal
      const deleteButtonQuery = `#${modalId} #modal-confirm-button`;
      const deleteButton = document.querySelector(deleteButtonQuery);
      deleteButton.setAttribute("data-current-id", this.idValue);
    } catch (e) {
      // In case of any type of error in setting the dataset value, stop the further actions i.e. opening the modal
      event.stopImmediatePropagation();
      throw e;
    }
  }
}
