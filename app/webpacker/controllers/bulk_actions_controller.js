import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
  }

  // abstract
  confirm(action) {
    this.stimulate(action, this.getSelectedIds());
  }

  // private
  getSelectedIds() {
    const checkboxes = document.querySelectorAll(
      "table input[name='bulk_ids[]']:checked"
    );
    return Array.from(checkboxes).map((checkbox) => checkbox.value);
  }
}
