import ApplicationController from "./application_controller";
export default class extends ApplicationController {
  static targets = ["valueProvider", "valueReceiver"];

  connect() {
    super.connect();
  }

  setSelectValue(event) {
    let selectedOptions = Array.from(event.currentTarget.selectedOptions);
    let lastOption = selectedOptions[selectedOptions.length - 1];
    let identifier = event.params.receiverIdentifier;

    let receiver = this.valueReceiverTargets.filter(
      (el) => el.id == identifier
    )[0];

    receiver.value = "";

    selectedOptions.forEach((option) => {
      if (option == lastOption) {
        receiver.value += option.value;
      } else {
        receiver.value += option.value + ",";
      }
    });
  }
}
