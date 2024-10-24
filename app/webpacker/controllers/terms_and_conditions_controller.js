import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["filename", "fileinput"];
  static values = {
    message: String,
  };

  connect() {
    this.fileinputTarget.addEventListener("change", (event) => {
      this.filenameTarget.innerText = event.target.files[0].name;
    });
  }

  add() {
    this.fileinputTarget.click();
  }
}
