import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["source", "select"];
  static values = { options: Array };

  connect() {
    this.populateSelect(parseInt(this.sourceTarget.value));
  }

  handleSelectChange() {
    this.populateSelect(parseInt(this.sourceTarget.value));
  }

  populateSelect(sourceId) {
    const allOptions = this.optionsValue;
    const options = allOptions.find((option) => option[0] === sourceId)[1];
    const selectBox = this.selectTarget;
    selectBox.innerHTML = "";
    options.forEach((item) => {
      const opt = document.createElement("option");
      opt.value = item[1];
      opt.innerHTML = item[0];
      selectBox.appendChild(opt);
    });
  }
}
