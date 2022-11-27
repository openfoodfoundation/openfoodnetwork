import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["reportType", "checkbox", "label"];

  handleSelectChange() {
    this.reportTypeTarget.value == "csv"
      ? this.disableField()
      : this.enableField();
  }

  disableField() {
    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = false;
      this.checkboxTarget.disabled = true;
    }
    if (this.hasLabelTarget) {
      this.labelTarget.classList.add("disabled");
    }
  }

  enableField() {
    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = true;
      this.checkboxTarget.disabled = false;
    }
    if (this.hasLabelTarget) {
      this.labelTarget.classList.remove("disabled");
    }
  }
}
