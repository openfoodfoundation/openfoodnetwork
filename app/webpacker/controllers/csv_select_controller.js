import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["reportType", "checkbox", "label"];

  connect() {
    this.applyMetadata();
  }

  handleSelectChange() {
    if (this.reportTypeTarget.value == "csv") {
      this.disableField();
    } else {
      this.enableField();
    }

    this.applyMetadata();
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

  // NEW: metadata-specific behavior
  applyMetadata() {
    const isCsv = this.reportTypeTarget?.value === "csv";
    const metaCheckbox = document.querySelector('input[name="display_metadata_rows"]');
    const metaLabel    = document.querySelector('label[for="display_metadata_rows"]');

    if (metaCheckbox) {
      metaCheckbox.disabled = !isCsv;
      if (!isCsv) metaCheckbox.checked = false; // optional
    }
    if (metaLabel) {
      metaLabel.classList.toggle("disabled", !isCsv);
    }
  }
}
