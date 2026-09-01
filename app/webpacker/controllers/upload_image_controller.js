import { Controller } from "stimulus";
import showHttpError from "../../webpacker/js/services/show_http_error";

export default class extends Controller {
  static values = { url: String, viewableId: Number };

  upload(event) {
    const file = event.target.files[0];
    if (!file) {
      return;
    }

    const formData = new FormData();
    formData.append("image[attachment]", file, file.name);
    formData.append("image[viewable_id]", this.viewableIdValue);
    formData.append("edit_after_upload", "true");

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");

    // The server decides where to go next: a redirect stream on success, a flash on failure.
    fetch(this.urlValue, {
      method: "POST",
      body: formData,
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken,
      },
    })
      .then((response) => response.text())
      .then((html) => Turbo.renderStreamMessage(html))
      .catch(() => showHttpError());
  }
}
