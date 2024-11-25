import { Controller } from "stimulus";

export default class extends Controller {
  static values = { enterpriseSells: String };
  static targets = ["spinner"];

  enterpriseSellsChanged(event) {
    console.log("enterpriseSellsChanged");
    if (event.currentTarget.checked) {
      this.enterpriseSellsValue = event.currentTarget.value;
      this.spinnerTarget.classList.remove("hidden");
      this.makeRequest();
    }
  }

  makeRequest() {
    fetch(
      `?stimulus=true&enterprise_sells=${this.enterpriseSellsValue}`,
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
