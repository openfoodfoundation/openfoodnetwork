import { Controller } from "stimulus";

// A confirm-only handler for links that should show a confirmation dialog
// without navigating. Turbo's FormLinkClickObserver requires data-turbo-method
// for data-turbo-confirm to fire on <a> tags, but that causes an unwanted
// page reload on "OK". This controller calls window.confirm and prevents
// default if the user cancels.
export default class extends Controller {
  static values = { message: String };

  confirm(event) {
    if (!window.confirm(this.messageValue)) {
      event.preventDefault();
    }
  }
}
