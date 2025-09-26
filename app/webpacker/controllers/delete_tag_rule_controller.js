import { Controller } from "stimulus";

export default class extends Controller {
  static values = { index: Number };

  delete(e) {
    // prevent default link action
    e.preventDefault();
    if (confirm(I18n.t("admin.tag_rules.confirm_delete")) == true) {
      document.getElementById(`tr_${this.indexValue}`).remove();
    }
  }
}
