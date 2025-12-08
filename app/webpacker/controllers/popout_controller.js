import { Controller } from "stimulus";

// Allows a form section to "pop out" and show additional options
export default class PopoutController extends Controller {
  static targets = ["button", "dialog"];
  static values = {
    updateDisplay: { Boolean, default: true },
  };

  connect() {
    this.displayElements = Array.from(this.element.querySelectorAll('input:not([type="hidden"])'));
    this.first_input = this.displayElements[0];

    // Show when click or down-arrow on button
    this.buttonTarget.addEventListener("click", this.show.bind(this));
    this.buttonTarget.addEventListener("keydown", this.applyKeyAction.bind(this));

    this.closeIfOutsideBound = this.closeIfOutside.bind(this); // Store reference for managing listeners.
  }

  disconnect() {
    // Clean up handlers registered outside the controller element.
    // (jest cleans up document too early)
    if (document) {
      this.#removeGlobalEventListeners();
    }
  }

  show(e) {
    this.dialogTarget.style.display = "block";
    this.first_input.focus();
    e.preventDefault();

    // Close when click or tab outside of dialog.
    this.#addGlobalEventListeners();
  }

  // Apply an appropriate action, behaving similar to a dropdown
  // Shows the popout and applies the value where appropriate
  applyKeyAction(e) {
    if ([38, 40].includes(e.keyCode)) {
      // Show if Up or Down arrow
      this.show(e);
    } else if (e.key.match(/^[\d\w]$/)) {
      // Show, and apply value if it's a digit or word character
      this.show(e);
      this.first_input.value = e.key;
      // Notify of change
      this.first_input.dispatchEvent(new Event("input"));
    }
  }

  close() {
    // Close if not already closed
    if (this.dialogTarget.style.display != "none") {
      // Check every element for browser-side validation, before the fields get hidden.
      if (!this.#enabledDisplayElements().every((element) => element.reportValidity())) {
        // If any fail, don't close
        return;
      }

      // Update button to represent any changes
      if (this.updateDisplayValue) {
        this.buttonTarget.textContent = this.#displayValue();
        this.buttonTarget.innerHTML ||= "&nbsp;"; // (with default space to help with styling)
      }
      this.buttonTarget.classList.toggle("changed", this.#isChanged());

      this.dialogTarget.style.display = "none";

      this.#removeGlobalEventListeners();
    }
  }

  closeIfOutside(e) {
    // Note that we need to ignore the clicked button. Even though the listener was only just
    // registered, it still fires sometimes for some unkown reason.
    if (!this.dialogTarget.contains(e.target) && !this.buttonTarget.contains(e.target)) {
      this.close();
    }
  }

  // Close if checked
  closeIfChecked(e) {
    if (e.target.checked) {
      this.close();
      this.buttonTarget.focus();
    }
  }

  // private

  // Summarise the active field(s)
  #displayValue() {
    let values = this.#enabledDisplayElements().map((element) => {
      if (element.type == "checkbox") {
        if (element.checked && element.labels[0]) {
          return element.labels[0].textContent.trim();
        }
      } else {
        return element.value;
      }
    });
    // Filter empty values and convert to string
    return values.filter(Boolean).join();
  }

  #isChanged() {
    return this.#enabledDisplayElements().some((element) => element.classList.contains("changed"));
  }

  #enabledDisplayElements() {
    return this.displayElements.filter((element) => !element.disabled);
  }

  #addGlobalEventListeners() {
    // Run async (don't block primary event handlers).
    document.addEventListener("click", this.closeIfOutsideBound, { passive: true });
    document.addEventListener("focusin", this.closeIfOutsideBound, { passive: true });
  }

  #removeGlobalEventListeners() {
    document.removeEventListener("click", this.closeIfOutsideBound);
    document.removeEventListener("focusin", this.closeIfOutsideBound);
  }
}
