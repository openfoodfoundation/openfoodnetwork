import { Controller } from "stimulus";

// Manages "changed" state for a form with multiple records
export default class BulkFormController extends Controller {
  static targets = ["actions", "changedSummary"];
  static values = {
    disableSelector: String,
    error: Boolean,
  };
  recordElements = {};

  connect() {
    this.form = this.element;

    // Start listening for any changes within the form
    // this.element.addEventListener('change', this.toggleChanged.bind(this)); // dunno why this doesn't work
    for (const element of this.form.elements) {
      element.addEventListener("input", this.toggleChanged.bind(this)); // immediately respond to any change

      // Set up a tree of fields according to their associated record
      const recordContainer = element.closest("[data-record-id]"); // The JS could be more efficient if this data was added to each element. But I didn't want to pollute the HTML too much.
      const recordId = recordContainer && recordContainer.dataset.recordId;
      if (recordId) {
        this.recordElements[recordId] ||= [];
        this.recordElements[recordId].push(element);
      }
    }

    this.toggleFormChanged();
  }

  disconnect() {
    // Make sure to clean up anything that happened outside
    this.#disableOtherElements(false);
    window.removeEventListener("beforeunload", this.preventLeavingBulkForm);
  }

  toggleChanged(e) {
    const element = e.target;
    element.classList.toggle("changed", this.#isChanged(element));

    this.toggleFormChanged();
  }

  toggleFormChanged() {
    // For each record, check if any fields are changed
    const changedRecordCount = Object.values(this.recordElements).filter((elements) =>
      elements.some(this.#isChanged)
    ).length;
    const formChanged = changedRecordCount > 0 || this.errorValue;

    // Show actions
    this.actionsTarget.classList.toggle("hidden", !formChanged);
    this.#disableOtherElements(formChanged); // like filters and sorting

    // Display number of records changed
    const key = this.hasChangedSummaryTarget && this.changedSummaryTarget.dataset.translationKey;
    if (key) {
      // TODO: save processing and only run if changedRecordCount has changed.
      this.changedSummaryTarget.textContent = I18n.t(key, { count: changedRecordCount });
    }

    // Prevent accidental data loss
    if (formChanged) {
      window.addEventListener("beforeunload", this.preventLeavingBulkForm);
    } else {
      window.removeEventListener("beforeunload", this.preventLeavingBulkForm);
    }
  }

  preventLeavingBulkForm(e) {
    // Cancel the event
    e.preventDefault();
    // Chrome requires returnValue to be set. Other browsers may display this if provided, but let's
    // not create a new translation key, and keep the behaviour consistent.
    e.returnValue = "";
  }

  // private

  #disableOtherElements(disable) {
    if (!this.hasDisableSelectorValue) return;

    this.disableElements ||= document.querySelectorAll(this.disableSelectorValue);

    if (!this.disableElements) return;

    this.disableElements.forEach((element) => {
      element.classList.toggle("disabled-section", disable);

      // Also disable any form elements
      let forms = element.tagName == "FORM" ? [element] : element.querySelectorAll("form");

      forms &&
        forms.forEach((form) =>
          Array.from(form.elements).forEach((formElement) => (formElement.disabled = disable))
        );
    });
  }

  #isChanged(element) {
    if (element.type == "checkbox") {
      return element.defaultChecked !== undefined && element.checked != element.defaultChecked;
    } else {
      return element.defaultValue !== undefined && element.value != element.defaultValue;
    }
  }
}
