import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  static targets = ["filename", "fileinput"];
  static values = {
    message: String,
  };

  connect() {
    super.connect();
    this.fileinputTarget.addEventListener("change", (event) => {
      this.filenameTarget.innerText = event.target.files[0].name;
    });
  }

  add() {
    this.fileinputTarget.click();
  }
}
