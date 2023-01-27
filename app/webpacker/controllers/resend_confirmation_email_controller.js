import BulkActionsController from "./bulk_actions_controller";

export default class extends BulkActionsController {
  connect() {
    super.connect();
  }

  confirm() {
    super.confirm("BulkActionsInOrdersList#resend_confirmation_email");
  }
}
