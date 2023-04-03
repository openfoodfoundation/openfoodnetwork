import { Controller } from "stimulus";

export default class extends Controller {
  static values = { initialPermalink: String, url: String };
  static targets = ["spinner", "permalinkField", "available", "unavailable"];

  initialize() {
    this.validate = _.debounce(this.validate, 300);
  }

  async validate() {
    this.hideAvailability();
    this.showSpinner();

    const response = await fetch(
      this.urlValue + `?permalink="${this.permalinkFieldTarget.value}"`
    );
    const result = await response.text();

    if (this.initialPermalinkValue == result) {
      this.permalinkFieldTarget.value = result;
      this.hideSpinner();
      return;
    }

    this.displayAvailability(response);

    this.hideSpinner();
    this.permalinkFieldTarget.value = result;
  }

  displayAvailability(response) {
    if (response.ok) {
      this.availableTarget.classList.remove("hidden");
    } else {
      this.unavailableTarget.classList.remove("hidden");
    }
  }

  hideAvailability() {
    this.availableTarget.classList.add("hidden");
    this.unavailableTarget.classList.add("hidden");
  }

  showSpinner() {
    this.spinnerTarget.classList.remove("hidden");
  }

  hideSpinner() {
    this.spinnerTarget.classList.add("hidden");
  }
}
