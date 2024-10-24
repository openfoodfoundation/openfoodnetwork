import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    this.element
      .querySelector("input")
      .addEventListener("keydown", this.searchOnEnter);
  }

  disconnect() {
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
