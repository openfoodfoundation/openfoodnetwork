import ApplicationController from "./application_controller";
import showHttpError from "../../webpacker/js/services/show_http_error";

export default class extends ApplicationController {
  static targets = ["extraParams"];
  static values = { reflex: String, url: String };

  connect() {
    super.connect();
  }

  perform() {
    let params = { bulk_ids: this.getSelectedIds() };

    if (this.hasExtraParamsTarget) {
      Object.assign(params, this.extraFormData());
    }

    this.stimulate(this.reflexValue, params);
  }

  turboPerform() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");
    let params = { bulk_ids: this.getSelectedIds() };

    if (this.hasExtraParamsTarget) {
      Object.assign(params, this.extraFormData());
    }

    fetch(this.urlValue, {
      method: "POST",
      body: JSON.stringify(params),
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken,
      },
    })
      .then((response) => {
        if (!response.ok) {
          showHttpError(response.status);
          throw response;
        }
        return response.text();
      })
      .then((html) => {
        Turbo.renderStreamMessage(html);
      })
      .catch((error) => console.error(error));
  }

  // private

  getSelectedIds() {
    const checkboxes = document.querySelectorAll("table input[name='bulk_ids[]']:checked");
    return Array.from(checkboxes).map((checkbox) => checkbox.value);
  }

  extraFormData() {
    if (this.extraParamsTarget.constructor.name !== "HTMLFormElement") {
      return {};
    }

    return Object.fromEntries(new FormData(this.extraParamsTarget).entries());
  }
}
