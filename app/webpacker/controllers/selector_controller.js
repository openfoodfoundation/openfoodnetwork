import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    window.addEventListener("click", this.closeOnClickOutside);
  }
  disconnect() {
    super.disconnect();
    window.removeEventListener("click", this.closeOnClickOutside);
  }

  closeOnClickOutside = (event) => {
    if (!this.element.contains(event.target)) {
      this.stimulate("SelectorComponent#close", this.element);
    }
  };
}
