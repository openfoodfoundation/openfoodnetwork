import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    window.addEventListener("orderCycleSelected", this.orderCycleSelected);
  }

  disconnect() {
    window.removeEventListener("orderCycleSelected", this.orderCycleSelected);
  }

  orderCycleSelected = (event) => {
    window.dispatchEvent(
      new CustomEvent("tabs-and-panels:click", {
        detail: {
          tab: "shop",
          panel: "shop_panel",
        },
      })
    );
  };
}
