import BulkActionsController from "./bulk_actions_controller";

export default class extends BulkActionsController {
  static targets = ["extraParams"]

  connect() {
    super.connect();
  }

  confirm() {
    let data = { bulk_ids: super.getSelectedIds() };

    if (this.hasExtraParamsTarget) {
      Object.assign(data, this.extraFormData())
    }

    this.stimulate("CancelOrdersReflex#confirm", data);
  }

  // private

  extraFormData() {
    if (this.extraParamsTarget.constructor.name !== "HTMLFormElement") { return {} }

    return Object.fromEntries(new FormData(this.extraParamsTarget).entries())
  }
}
