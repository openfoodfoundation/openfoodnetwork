import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["source", "select"];
  static values = { options: Array };

  handleSelectChange() {
    this.populateSelect(parseInt(this.sourceTarget.value));
  }

  // private

  populateSelect(sourceId) {
    this.tomselect = this.selectTarget.tomselect;
    this.removeCurrentOptions();
    this.populateNewOptions(sourceId);
  }

  removeCurrentOptions() {
    this.selectTarget.innerHTML = "";

    if (!this.tomselect) {
      return;
    }

    this.tomselect.clear();
    this.tomselect.clearOptions();
  }

  populateNewOptions(sourceId) {
    const options = this.dependentOptionsFor(sourceId);

    options.forEach((item) => {
      this.addOption(item[0], item[1]);
    });

    if (!this.tomselect) {
      return;
    }

    if (options.length == 0) {
      this.tomselect.disable();
    } else {
      this.tomselect.enable();
      this.tomselect.addItem(options[0]?.[1]);
      this.tomselect.sync();
      this.tomselect.setValue(null);
    }
  }

  addOption(label, value) {
    const newOption = document.createElement("option");
    newOption.innerHTML = label;
    newOption.value = value;
    this.selectTarget.appendChild(newOption);
  }

  dependentOptionsFor(sourceId) {
    let options = this.optionsValue.find((option) => option[0] === sourceId);
    return options ? options[1] : [];
  }
}
