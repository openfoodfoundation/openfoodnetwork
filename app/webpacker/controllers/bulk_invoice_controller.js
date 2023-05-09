import BulkActionsController from "./bulk_actions_controller";

export default class extends BulkActionsController {
  connect() {
    super.connect();
  }

  generate() {
    this.stimulate("Admin::OrdersReflex#bulk_invoice", { order_ids: super.getOrdersIds() });
  }
}
