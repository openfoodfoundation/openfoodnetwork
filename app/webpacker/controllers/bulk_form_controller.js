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
    this.#observeProductsTableRows();
  }

  disconnect() {
    // Make sure to clean up anything that happened outside
    this.#disableOtherElements(false);
    window.removeEventListener("beforeunload", this.preventLeavingChangedForm.bind(this));
    this.productsTableObserver.disconnect();
  }

  // Register any new elements (may be called by another controller after dynamically adding fields)
  // May be called with array of elements to register, otherwise finds all un-registered elements.
  registerElements(eventOrElements = null) {
    let newElements;

    if (Array.isArray(eventOrElements)) {
      newElements = eventOrElements;
    } else {
      const registeredElements = Object.values(this.recordElements).flat();
      // Select only elements that haven't been registered yet
      newElements = Array.from(this.form.elements).filter((n) => !registeredElements.includes(n));
    }

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

  // Pop out empty variant unit to allow browser side validation to focus the element
  popoutEmptyVariantUnit() {
    this.variantUnits = this.element.querySelectorAll("button.popout__button");
    this.variantUnits.forEach((element) => {
      if (element.textContent == "") {
        element.click();
      }
    });
  }

  // private

  #registerSubmit() {
    this.submitting = true;
    this.#filterSubmittedFields();
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

  #filterSubmittedFields() {
    const recordContainers = this.form.querySelectorAll("[data-record-id]");

    recordContainers.forEach((container) => {
      const elements = Array.from(container.querySelectorAll("input, select, textarea, button"));
      const changedElements = elements.filter((element) => this.#isChanged(element));

      elements.forEach((element) => {
        if (element.type !== "submit") {
          element.disabled = true;
        }
      });

      if (changedElements.length === 0) return;

      // When re-submitting after validation errors, submit all fields in the
      // record container so previously-valid field values aren't dropped just because
      // they match the server-rendered defaults from the error recovery page
      const elementsToSubmit = this.errorValue ? elements : changedElements;

      this.#enableElementsForSubmit(elementsToSubmit);
      this.#enableRecordIdentityFields(container);
    });
  }

  #enableElementsForSubmit(changedElements) {
    changedElements.forEach((element) => {
      this.#enableElement(element);
      // Rails check_box helper generates a hidden+checkbox pair sharing the
      // same name. When only the checkbox is re-enabled, unchecking it
      // submits nothing (unchecked checkboxes don't submit). Enable the
      // hidden sibling so the "0" value is sent on uncheck.
      if (element.type === "checkbox") {
        const hiddenSibling = element.previousElementSibling;
        if (hiddenSibling?.type === "hidden" && hiddenSibling.name === element.name) {
          this.#enableElement(hiddenSibling);
        }
      }
    });
  }

  #enableRecordIdentityFields(recordContainer) {
    const changedVariantRows = new Set(
      this.recordElements[recordContainer.dataset.recordId]
        .filter((element) => this.#isChanged(element))
        .map((element) => element.closest("[id^='spree_variant_'], [data-new-record]"))
        .filter((container) => container),
    );

    this.#recordIdentityFields(recordContainer).forEach((field) => this.#enableElement(field));

    changedVariantRows.forEach((variantRow) => {
      this.#variantIdentityFields(variantRow).forEach((field) => this.#enableElement(field));
    });
  }

  #enableElement(element) {
    if (element) {
      element.disabled = false;
    }
  }

  #recordIdentityFields(recordContainer) {
    return Array.from(
      recordContainer.querySelectorAll('input[type="hidden"][name$="[id]"]'),
    ).filter((element) => !element.closest("[id^='spree_variant_'], [data-new-record]"));
  }

  #variantIdentityFields(variantRow) {
    return Array.from(variantRow.querySelectorAll('input[type="hidden"][name$="[id]"]'));
  }

  // Check if changed, and mark with class if it is.
  #checkIsChanged(element) {
    if (!element.isConnected) return false;

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
      // Compare by value instead of DOM element reference.
      // Tom Select can create duplicate <option> DOM elements during remote
      // search, so reference comparison (===) fails after revert.
      const defaultOption = Array.from(element.options).find((opt) => opt.defaultSelected);
      const defaultValue = defaultOption?.value ?? "";
      const noDefaultSelected = defaultOption === undefined && element.value === "";

      return !noDefaultSelected && element.value !== defaultValue;
    } else {
      // This doesn't work with hidden field
      //   Workaround: use a text field with "display:none;"
      return element.defaultValue !== undefined && element.value != element.defaultValue;
    }
  }

  #removeAnimationClasses(productRowElement) {
    productRowElement.classList.remove("slide-in");
    productRowElement.removeEventListener(
      "animationend",
      this.#removeAnimationClasses.bind(this, productRowElement),
    );
  }

  #observeProductsTableRows() {
    this.productsTableObserver = new MutationObserver((mutationList, _observer) => {
      const mutationRecord = mutationList[0];

      if (mutationRecord) {
        // Right now we are only using it for product clone, so it's always first
        const productRowElement = mutationRecord.addedNodes[0];

        if (productRowElement) {
          productRowElement.addEventListener(
            "animationend",
            this.#removeAnimationClasses.bind(this, productRowElement),
          );
          // This is equivalent to form.elements.
          const productRowFormElements = productRowElement.querySelectorAll(
            "input, select, textarea, button",
          );
          this.#registerElements(productRowFormElements);
          this.toggleFormChanged();
        }
      }
    });

    const productsTable = document.querySelector(".products");
    // Above mutation function will trigger,
    // whenever +products+ table rows (first level children) are mutated i.e. added or removed
    // right now we are using this for product clone
    this.productsTableObserver.observe(productsTable, { childList: true });
  }
}
