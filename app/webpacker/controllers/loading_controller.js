import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
  }

  hideLoading = () => {
    this.element.classList.add("hidden");
  };

  showLoading = () => {
    this.element.classList.remove("hidden");
  };
}
