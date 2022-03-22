import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    window.addEventListener("click", this.handleClick);
  }
  disconnect() {
    super.disconnect();
    window.removeEventListener("click", this.handleClick);
  }

  handleClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.stimulate("SuperSelectorComponent#close", this.element);
    }
  };
}
