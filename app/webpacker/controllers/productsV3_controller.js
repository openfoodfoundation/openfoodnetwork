import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    // Fetch the products on page load
    this.load();
  }

  load = () => {
    this.stimulate("Admin::ProductsV3#fetch");
  };
}
