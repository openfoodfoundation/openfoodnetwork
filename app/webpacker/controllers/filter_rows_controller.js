import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["row"];

  filter(event) {
    const query = event.target.value.toLowerCase();
    this.rowTargets.forEach((row) => {
      if (row.dataset.searchable.toLowerCase().includes(query)) {
        row.style.display = "";
      } else {
        console.log("hiding for: ", row.dataset.searchable);
        row.style.display = "none";
      }
    });
  }
}
