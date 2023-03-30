import { Controller } from "stimulus";

export default class extends Controller {
  static values = { primaryProducer: String, enterpriseSells: String };
  static targets = ["spinner"];

  primaryProducerChanged(event) {
    this.primaryProducerValue = event.currentTarget.checked;
    this.makeRequest();
  }

  enterpriseSellsChanged(event) {
    if (event.currentTarget.checked) {
      this.enterpriseSellsValue = event.currentTarget.value;
      this.spinnerTarget.classList.remove("hidden");
      this.makeRequest();
    }
  }

  makeRequest() {
    fetch(
      `?stimulus=true&enterprise_sells=${this.enterpriseSellsValue}&is_primary_producer=${this.primaryProducerValue}`,
      {
        method: "GET",
        headers: { "Content-type": "application/json; charset=UTF-8" },
      }
    )
      .then((data) => data.json())
      .then((operation) => {
        CableReady.perform(operation);
        this.spinnerTarget.classList.add("hidden");
      });
  }
}
