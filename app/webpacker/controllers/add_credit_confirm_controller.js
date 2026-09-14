import { Controller } from "stimulus";

// Keeps the "Add Credit" submit button's confirm dialog in sync with the
// amount typed into the form, so it states the actual amount being applied
// instead of a generic "Are you sure?".
export default class extends Controller {
  static targets = ["amount", "submit"];
  static values = { currency: String };

  connect() {
    this.updateConfirmMessage();
  }

  updateConfirmMessage() {
    this.submitTarget.dataset.turboConfirm = I18n.t(
      "admin.customer_account_transaction.form.confirm",
      { currency: this.currencyValue, amount: this.amountTarget.value },
    );
  }
}
