import { Controller } from "stimulus";

export default class FormController extends Controller {
  submit() {
    this.element.submit();
  }
}
