import ApplicationController from "./application_controller";
export default class extends ApplicationController {
  static targets = ["parent", "child"];
  connect() {
    super.connect();
  }

  enableTomSelect({ params: { dependentIdentifier } }) {
    this.childTargets.forEach((el) => {
      let control = el.tomselect;
      el.id == dependentIdentifier ? control.enable() : control.disable();
    });
  }
}
