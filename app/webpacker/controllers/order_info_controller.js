import { Controller } from "stimulus";

export default class extends Controller {
  static values = { orderNumber: String };
  static targets = ["editor", "editField", "resourceDisplayer"];

  showEditor() {
    this.editorTarget.classList.remove("hidden");
    this.editFieldTarget.focus();
    this.editFieldTarget.setSelectionRange(-1, -1);
    this.resourceDisplayerTarget.classList.add("hidden");
  }

  hideEditor() {
    this.editorTarget.classList.add("hidden");
    this.resourceDisplayerTarget.classList.remove("hidden");
  }

  save() {
    let data = this.editFieldTarget.value;
    this.makeApiCall(this.params(data));
  }

  makeApiCall(params) {
    fetch(this.url, {
      method: "PUT",
      body: JSON.stringify(params),
      headers: { "Content-type": "application/json; charset=UTF-8" },
    }).then(function (response) {
      if (response.ok) {
        window.location.reload();
      } else {
        console.error(response);
      }
    });
  }

  params(data) {
    return { note: data };
  }

  get url() {
    return Spree.url(Spree.routes.orders_api + "/" + this.orderNumberValue);
  }
}
