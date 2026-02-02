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
  if (!event.detail.success) {
    // show error message on failure
    showHttpError(event.detail.fetchResponse?.statusCode);
    event.preventDefault();
  }
});
