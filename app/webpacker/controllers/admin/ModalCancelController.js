import { Controller } from "stimulus";

export class ModalCancelController extends Controller {
  initialize() {
    this.boundClickCancelBtn = this.clickCancelButton.bind(this);
    this.boundClickConfirmBtn = this.clickConfirmBtn.bind(this);
    this.cancelButton = this.S("#custom-confirm button.cancel");
    this.confirmButton = this.S("#custom-confirm button.confirm");
  }

  S(selector) {
    return document.querySelector(selector);
  }

  showModal(...args) {
    this.addContentMessage(...args);
    this.addButtonListeners();
    this.showCustomConfirm();
  }

  addContentMessage(callback, i18nKey) {
    if (i18nKey == undefined) {
      i18nKey = "js.admin.orders.cancel_the_order_html";
    }
    this.S("#custom-confirm .message").innerHTML = `   ${t(i18nKey)}
        <div class="form">
          <input type="checkbox" name="send_cancellation_email" value="1" id="send_cancellation_email" checked="true" />
          <label for="send_cancellation_email">${t(
            "js.admin.orders.cancel_the_order_send_cancelation_email"
          )}</label><br />
          <input type="checkbox" name="restock_items"  id="restock_items" checked="checked"/>
          <label for="restock_items">${t(
            "js.admin.orders.restock_items"
          )}</label>
        </div>`;
  }

  addButtonListeners() {
    this.cancelButton.addEventListener("click", this.boundClickCancelBtn);
    this.confirmButton.addEventListener("click", this.boundClickConfirmBtn);
  }

  clickCancelButton() {
    this.hideCustomConfirm();
    this.callback(false);
    this.unbindButtons();
  }

  clickConfirmBtn() {
    this.hideCustomConfirm();
    this.callback(
      true,
      this.S("#send_cancellation_email").checked,
      this.S("#restock_items").checked
    );
    this.unbindButtons();
  }

  unbindButtons() {
    this.unbindCancelBtn();
    this.unbindConfirmBtn();
  }

  unbindCancelBtn() {
    this.cancelButton.removeEventListener("click", this.boundClickCancelBtn);
  }

  unbindConfirmBtn() {
    this.confirmButton.removeEventListener("click", this.boundClickConfirmBtn);
  }

  showCustomConfirm() {
    this.S("#custom-confirm").style.display = "block";
  }

  hideCustomConfirm() {
    this.S("#custom-confirm").style.display = "none";
  }
}
