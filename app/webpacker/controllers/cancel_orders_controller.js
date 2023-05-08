import BulkActionsController from "./bulk_actions_controller";

export default class extends BulkActionsController {
  static targets = ["extraParams"]

  connect() {
    super.connect();
  }

  confirm() {
    let data = { order_ids: super.getOrdersIds() };

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
