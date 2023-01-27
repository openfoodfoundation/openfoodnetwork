import BulkActionsController from "./bulk_actions_controller";

export default class extends BulkActionsController {
  connect() {
    super.connect();
  }

  confirm() {
    super.confirm("ResendConfirmationEmailReflex#confirm");
  }
}
