import { Controller } from "stimulus";

// Manages "modified" state for a form with multiple records
export default class BulkFormController extends Controller {
  connect() {
    this.form = this.element;

    // Start listening for any changes within the form
    // this.element.addEventListener('change', this.toggleModified.bind(this)); // dunno why this doesn't work
    for (const element of this.form.elements) {
      element.addEventListener("keyup", this.toggleModified.bind(this)); // instant response
      element.addEventListener("change", this.toggleModified.bind(this)); // just in case (eg right-click paste)
    }
  }

  toggleModified(e) {
    const element = e.target;
    const changed = element.value != element.defaultValue;
    element.classList.toggle("modified", changed);
  }
}
