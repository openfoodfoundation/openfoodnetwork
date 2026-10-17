import { Controller } from "stimulus";
import showHttpError from "js/services/show_http_error";
import { navigateToLocation, reloadLocation } from "js/window_location_wrapper";

export default class extends Controller {
  static values = { method: String, confirmMessage: String, redirectTo: String };

  request(event) {
    event.preventDefault();

    if (this.hasConfirmMessageValue && !window.confirm(this.confirmMessageValue)) {
      return;
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");

    fetch(this.element.href, {
      method: this.methodValue,
      headers: {
        Accept: "text/html",
        "X-CSRF-Token": csrfToken,
      },
      redirect: "manual",
    })
      .then((response) => {
        // The server mutates state and redirects with a flash stored in the
        // session. `redirect: "manual"` leaves that redirect un-followed so the
        // flash isn't consumed by an intermediate page render. Navigating to the
        // target (or reloading) then shows the flash and re-bootstraps any
        // AngularJS app, which Turbo soft-navigation would otherwise skip.
        if (response.type === "opaqueredirect") {
          if (this.hasRedirectToValue) {
            navigateToLocation(this.redirectToValue);
          } else {
            reloadLocation();
          }
        } else {
          showHttpError(response.status);
        }
      })
      .catch((error) => console.error(error));
  }
}
