import { Controller } from "stimulus";

export default class extends Controller {
  static values = { translation: String };

  connect() {
    window.addEventListener("checked:updated", this.updateFeedback);
  }

  disconnect() {
    window.removeEventListener("checked:updated", this.updateFeedback);
  }

  updateFeedback = (event) => {
    this.element.textContent = I18n.t(this.translationValue, {
      count: event?.detail?.count ? event.detail.count : 0,
    });
  };
}
