import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["extraParams"]
  static values = { reflex: String }

  connect() {
    super.connect();
  }

  perform() {
    let params = { bulk_ids: this.getSelectedIds() };

    if (this.hasExtraParamsTarget) {
      Object.assign(params, this.extraFormData())
    }

    this.stimulate(this.reflexValue, params);
  }

  // private

  getSelectedIds() {
    const checkboxes = document.querySelectorAll(
      "table input[name='bulk_ids[]']:checked"
    );
    return Array.from(checkboxes).map((checkbox) => checkbox.value);
  }

  extraFormData() {
    if (this.extraParamsTarget.constructor.name !== "HTMLFormElement") { return {} }

    return Object.fromEntries(new FormData(this.extraParamsTarget).entries())
  }
}
