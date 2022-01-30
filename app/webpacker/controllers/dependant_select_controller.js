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
    this.removeCurrentOptions()

    this.dependantOptionsFor(sourceId).forEach((item) => {
      this.addOption(item[0], item[1])
    });
  }

  removeCurrentOptions() {
    this.selectTarget.innerHTML = ""
  }

  addOption(label, value) {
    const newOption = document.createElement("option")
    newOption.innerHTML = label
    newOption.value = value
    this.selectTarget.appendChild(newOption)
  }

  dependantOptionsFor(sourceId) {
    return this.optionsValue.find((option) => option[0] === sourceId)[1]
  }
}
