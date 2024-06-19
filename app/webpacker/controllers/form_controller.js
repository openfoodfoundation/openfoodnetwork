import { Controller } from "stimulus";

export default class FormController extends Controller {
  submit() {
    // Validate and submit the form, using the default submit button. Raises JS events.
    // Ref: https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/requestSubmit
    this.element.requestSubmit();
  }
}
