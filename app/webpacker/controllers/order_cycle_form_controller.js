import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ['statusMessage']
  connect() {
    console.log(this.statusMessageTarget)
    this.observer = new MutationObserver(this.updateCallback);
    this.observer.observe(
      this.statusMessageTarget,
      { attributes: true, attributeOldValue: true, attributeFilter: ['data-type'] }
    );
  }

  // Callback to trigger warning modal
  updateCallback(mutationsList) {
    const newDataType = document.getElementById('status-message').getAttribute('data-type');
    const actionName = document.getElementById('status-message').getAttribute('data-action-name');
    if(!actionName) return;

    for(let mutation of mutationsList) {
      if (mutation.type === 'attributes' && mutation.attributeName === 'data-type') {
        // Only trigger warning modal when notice display (notice) is preceeded by progress display (progress)
        if(mutation.oldValue === 'progress' && newDataType === 'notice') {
          // Hide all confirmation buttons in warning modal
          document.querySelectorAll(
            '#linked-order-warning-modal .modal-actions button.secondary'
          ).forEach((node) => {
            node.style.display = 'none';
          });
          // Show the appropriate confirmation button, open warning modal, and return
          document.querySelectorAll(
            `#linked-order-warning-modal button[data-trigger-action=${actionName}]`
          ).forEach((node) => {
            node.style.display = 'block';
          })
          document.querySelector('.warning-modal button.modal-target-trigger').click();
        }
      }
    }
  }

  disconnect() {
    this.observer.disconnect();
  }
}
