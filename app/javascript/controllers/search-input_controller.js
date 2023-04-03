import ApplicationController from "./application_controller";

export default class extends ApplicationController {
  connect() {
    super.connect();
    this.element
      .querySelector("input")
      .addEventListener("keydown", this.searchOnEnter);
  }

  disconnect() {
    super.disconnect();
    this.element
      .querySelector("input")
      .removeEventListener("keydown", this.searchOnEnter);
  }

  searchOnEnter = (e) => {
    if (e.key === "Enter") {
      this.element.querySelector(".search-button").click();
    }
  };

  search(e) {
    this.element.querySelector(".search-button").dataset["value"] =
      e.target.value;
  }
}
