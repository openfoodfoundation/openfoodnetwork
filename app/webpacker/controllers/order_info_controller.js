import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["editor", "editField", "resourceDisplayer"];

  showEditor() {
    this.editorTarget.classList.remove("hidden");
    this.editFieldTarget.focus();
    this.editFieldTarget.setSelectionRange(-1, -1);
    this.resourceDisplayerTarget.classList.add("hidden");
  }

  hideEditor() {
    this.editorTarget.classList.add("hidden");
    this.resourceDisplayerTarget.classList.remove("hidden");
  }
}
