import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['element']
  connect() {
    this.observer = new MutationObserver(this.updateCallback);
    this.observer.observe(
      this.elementTarget,
      { attributes: true, attributeOldValue: true, attributeFilter: ['data-type'] }
    );
  }

  // Callback to trigger warning modal
  updateCallback(mutationsList) {
    const newDataType =  $('#status-message').attr('data-type');
    const actionName =  $('#status-message').attr('data-action-name');
    if(!actionName) return;

    for(let mutation of mutationsList) {
      if (mutation.type === 'attributes' && mutation.attributeName === 'data-type') {
        // Only trigger warning modal when notice display (notice) is preceeded by progress display (progress)
        if(mutation.oldValue === 'progress' && newDataType === 'notice') {
          // Hide all confirmation buttons in warning modal
          $('#linked-order-warning-modal .modal-actions button.secondary').css({ display: 'none' })
          // Show the appropriate confirmation button, open warning modal, and return
          $(`#linked-order-warning-modal button[data-trigger-action=${actionName}]`).css({ display: 'block' });
          $('.warning-modal button.modal-target-trigger').trigger('click');
        }
      }
    }
  }

  disconnect() {
    this.observer.disconnect();
  }
}
