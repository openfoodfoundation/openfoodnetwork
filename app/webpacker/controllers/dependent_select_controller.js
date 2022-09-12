import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["source", "select"];
  static values = { options: Array };

  handleSelectChange() {
    this.populateSelect(parseInt(this.sourceTarget.value));
  }

  // private

  populateSelect(sourceId) {
    this.removeCurrentOptions();
    this.populateNewOptions(sourceId);
  }

  removeCurrentOptions() {
    this.selectTarget.innerHTML = "";

    this.selectTarget.tomselect?.clear();
    this.selectTarget.tomselect?.clearOptions();
  }

  populateNewOptions(sourceId) {
    const options = this.dependentOptionsFor(sourceId);

    options.forEach((item) => {
      this.addOption(item[0], item[1]);
    });

    this.selectTarget.tomselect?.sync();
    this.selectTarget.tomselect?.addItem(options[0]?.[1]);
  }

  addOption(label, value) {
    const newOption = document.createElement("option");
    newOption.innerHTML = label;
    newOption.value = value;
    this.selectTarget.appendChild(newOption);
  }

  dependentOptionsFor(sourceId) {
    return this.optionsValue.find((option) => option[0] === sourceId)[1];
  }
}
