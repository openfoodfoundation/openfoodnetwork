import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["reportType", "checkbox", "label"];

  handleSelectChange() {
    this.reportTypeTarget.value == "csv"
      ? this.disableField()
      : this.enableField();
  }

  disableField() {
    this.checkboxTarget.checked = false;
    this.checkboxTarget.disabled = true;
    this.labelTarget.classList.add("disabled");
  }

  enableField() {
    this.checkboxTarget.checked = true;
    this.checkboxTarget.disabled = false;
    this.labelTarget.classList.remove("disabled");
  }
}
