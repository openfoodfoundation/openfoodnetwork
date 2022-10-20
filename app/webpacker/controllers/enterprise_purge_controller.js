import ApplicationController from "./application_controller";
export default class extends ApplicationController {
  static values = {
    confirmMessage: String,
  };

  connect() {
    super.connect();
  }

  logo(event) {
    let confirmation = confirm(this.confirmMessageValue);
    if (!confirmation) return;
    this.stimulate("EnterprisePurge#logo", event.currentTarget);
  }

  promoImage(event) {
    let confirmation = confirm(this.confirmMessageValue);
    if (!confirmation) return;
    this.stimulate("EnterprisePurge#promo_image", event.currentTarget);
  }
}
