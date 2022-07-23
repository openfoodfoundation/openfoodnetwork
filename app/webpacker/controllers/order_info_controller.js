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

  remove() {
    let data = "";
    this.confirmRemove(this.params(data));
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

  confirmRemove(params) {
    this.displayAlert((confirmation) => {
      if (confirmation) {
        this.makeApiCall(params);
      }
    });
  }

  displayAlert(callback) {
    let alertBox = document.querySelector("#custom-confirm");
    let cancelBtn = alertBox.querySelector("button.cancel");
    let confirmBtn = alertBox.querySelector("button.confirm");

    confirmBtn.addEventListener("click", function () {
      alertBox.style.display = "none";
      callback(true);
    });

    cancelBtn.addEventListener("click", function () {
      alertBox.style.display = "none";
      callback(false);
    });

    alertBox.style.display = "block";
  }

  get url() {
    return Spree.url(Spree.routes.orders_api + "/" + this.orderNumberValue);
  }
}
