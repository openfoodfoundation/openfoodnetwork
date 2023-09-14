import { Controller } from "stimulus";

// Manages "modified" state for a form with multiple records
export default class BulkFormController extends Controller {
  static targets = ["actions", "modifiedSummary"];
  static values = {
    disableSelector: String,
  };
  recordElements = {};

  connect() {
    this.form = this.element;

    // Start listening for any changes within the form
    // this.element.addEventListener('change', this.toggleModified.bind(this)); // dunno why this doesn't work
    for (const element of this.form.elements) {
      element.addEventListener("keyup", this.toggleModified.bind(this)); // instant response
      element.addEventListener("change", this.toggleModified.bind(this)); // just in case (eg right-click paste)

      // Set up a tree of fields according to their associated record
      const recordContainer = element.closest("[data-record-id]"); // The JS could be more efficient if this data was added to each element. But I didn't want to pollute the HTML too much.
      const recordId = recordContainer && recordContainer.dataset.recordId;
      if (recordId) {
        this.recordElements[recordId] ||= [];
        this.recordElements[recordId].push(element);
      }
    }
  }

  disconnect() {
    // Make sure to clean up anything that happened outside
    this.#disableOtherElements(false);
  }

  toggleModified(e) {
    const element = e.target;
    const modified = element.value != element.defaultValue;
    element.classList.toggle("modified", modified);

    this.toggleFormModified();
  }

  toggleFormModified() {
    // For each record, check if any fields are modified
    const modifiedRecordCount = Object.keys(this.recordElements).filter((recordId) => {
      return this.recordElements[recordId].some((element) => {
        return element.value != element.defaultValue;
      });
    }).length;
    const formModified = modifiedRecordCount > 0;

    // Show actions
    this.actionsTarget.classList.toggle("hidden", !formModified);
    this.#disableOtherElements(formModified); // like filters and sorting

    // Display number of records modified
    const key = this.modifiedSummaryTarget && this.modifiedSummaryTarget.dataset.translationKey;
    if (key) {
      this.modifiedSummaryTarget.textContent = I18n.t(key, { count: modifiedRecordCount });
    }
  }

  // private

  #disableOtherElements(disable) {
    this.disableElements ||= document.querySelectorAll(this.disableSelectorValue);

    if (this.disableElements) {
      this.disableElements.forEach((element) => {
        element.classList.toggle("disabled-section", disable);
      });
    }
  }
}
