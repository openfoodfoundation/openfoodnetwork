import "@hotwired/turbo";
import showHttpError from "./services/show_http_error";

import TurboPower from "turbo_power";
TurboPower.initialize(Turbo.StreamActions);

document.addEventListener("turbo:frame-missing", (event) => {
  // don't replace frame contents
  event.preventDefault();

  // show error message instead
  showHttpError(event.detail.response?.status);
});

document.addEventListener("turbo:submit-end", (event) => {
  // Only show alert if there was a fetch error.
  // No alert needed if unsuccessful due to user abort.
  if (!event.detail.success && event.detail.error) {
    // show error message on failure
    showHttpError(event.detail.fetchResponse?.statusCode);
  }
});
