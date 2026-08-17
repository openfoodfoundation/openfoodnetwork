import { Controller } from "stimulus";

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
    formData.append("redirect_to_edit", "true");

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");

    fetch(this.urlValue, {
      method: "POST",
      body: formData,
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken,
      },
    })
      .then((response) => {
        if (response.ok) {
          return response.json().then((data) => {
            if (data.redirect_url) {
              this.navigateTo(data.redirect_url);
            }
          });
        }
        return response.text().then((html) => Turbo.renderStreamMessage(html));
      })
      .catch((error) => console.error(error));
  }

  // Extracted so tests can observe the redirect: jsdom makes window.location unstubbable.
  navigateTo(url) {
    window.location.href = url;
  }
}
