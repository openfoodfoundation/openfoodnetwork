import { Controller } from "stimulus";

// Manage "changed" state for a form with multiple records
//
// When any elements are changed:
//  - the element is marked ".changed"
//  - "actions" element appears
//  - "changedSummary" element is updated using I18n
//  - "disableSelector" elements are disabled
//  - The browser will warn if trying to leave the page
//
// Supported element types:
//  - input[type=text] and similar
//  - input[type=checkbox]
//  - select (single) - including tom-select
//
export default class BulkFormController extends Controller {
  static targets = ["actions", "changedSummary"];
  static values = {
    disableSelector: String,
    error: Boolean,
  };
  recordElements = {};

  connect() {
    this.submitting = false;
    this.form = this.element;

    // Start listening for any changes within the form
    this.#registerElements(this.form.elements);

    this.toggleFormChanged();

    this.form.addEventListener("submit", this.#registerSubmit.bind(this));
    window.addEventListener("beforeunload", this.preventLeavingChangedForm.bind(this));
  }

  disconnect() {
    // Make sure to clean up anything that happened outside
    this.#disableOtherElements(false);
    window.removeEventListener("beforeunload", this.preventLeavingChangedForm.bind(this));
  }

  // Register any new elements (may be called by another controller after dynamically adding fields)
  registerElements() {
    const registeredElements = Object.values(this.recordElements).flat();
    // Select only elements that haven't been registered yet
    const newElements = Array.from(this.form.elements).filter(
      (n) => !registeredElements.includes(n),
    );

    this.#registerElements(newElements);
  }

  toggleChanged(e) {
    const element = e.target;
    element.classList.toggle("changed", this.#isChanged(element));

    this.toggleFormChanged();
  }

  toggleFormChanged() {
    // For each record, check if any fields are changed
    // TODO: optimise basd on current state. if field is changed, but form already changed, no need to update (and vice versa)
    const changedRecordCount = Object.values(this.recordElements).filter((elements) =>
      elements.some(this.#checkIsChanged.bind(this)),
    ).length;
    this.formChanged = changedRecordCount > 0 || this.errorValue;

    // Show actions
    this.hasActionsTarget && this.actionsTarget.classList.toggle("hidden", !this.formChanged);
    this.#disableOtherElements(this.formChanged); // like filters and sorting

    // Display number of records changed
    const key = this.hasChangedSummaryTarget && this.changedSummaryTarget.dataset.translationKey;
    if (key) {
      // TODO: save processing and only run if changedRecordCount has changed.
      this.changedSummaryTarget.textContent = I18n.t(key, { count: changedRecordCount });
    }
  }

  // If form is not being submitted, warn to prevent accidental data loss
  preventLeavingChangedForm(event) {
    if (this.formChanged && !this.submitting) {
      // Cancel the event
      event.preventDefault();
      // Chrome requires returnValue to be set, but ignores the value. Other browsers may display
      // this if provided, but let's not create a new translation key, and keep the behaviour
      // consistent.
      event.returnValue = "";
    }
  }

  // private

  #registerSubmit() {
    this.submitting = true;
  }

  #registerElements(elements) {
    for (const element of elements) {
      element.addEventListener("input", this.toggleChanged.bind(this)); // immediately respond to any change

      // Set up a tree of fields according to their associated record
      const recordContainer = element.closest("[data-record-id]"); // The JS could be more efficient if this data was added to each element. But I didn't want to pollute the HTML too much.
      const recordId = recordContainer && recordContainer.dataset.recordId;
      if (recordId) {
        this.recordElements[recordId] ||= [];
        this.recordElements[recordId].push(element);
      }
    }
  }

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
          Array.from(form.elements).forEach((formElement) => (formElement.disabled = disable)),
        );
    });
  }

  // Check if changed, and mark with class if it is.
  #checkIsChanged(element) {
    if(!element.isConnected) return false;

    const changed = this.#isChanged(element);
    element.classList.toggle("changed", changed);
    return changed;
  }

  #isChanged(element) {
     if (element.type == "checkbox") {
      return element.defaultChecked !== undefined && element.checked != element.defaultChecked;

    } else if (element.type == "select-one") {
      // (weird) Behavior of select element's include_blank option in Rails:
      //   If a select field has include_blank option selected (its value will be ''),
      //   its respective option doesn't have the selected attribute
      //   but selectedOptions have that option present
      const defaultSelected = Array.from(element.options).find((opt) =>
        opt.hasAttribute("selected"),
      );
      const selectedOption = element.selectedOptions[0];
      const areBothBlank = selectedOption.value === '' && defaultSelected === undefined

      return !areBothBlank && selectedOption !== defaultSelected;

    } else {
      return element.defaultValue !== undefined && element.value != element.defaultValue;
    }
  }
}
