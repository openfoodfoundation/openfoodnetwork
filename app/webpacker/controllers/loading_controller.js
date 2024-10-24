import { Controller } from "stimulus";

export default class extends Controller {
  hideLoading = () => {
    this.element.classList.add("hidden");
  };

  showLoading = () => {
    this.element.classList.remove("hidden");
  };
}
