import "@hotwired/turbo";
import showHttpError from "./services/show_http_error";

import TurboPower from "turbo_power";
TurboPower.initialize(Turbo.StreamActions);

document.addEventListener("turbo:frame-missing", (event) => {
  // don't replace frame contents
  event.preventDefault();

  // show error message instead
  showHttpError(event.detail.response);
});

document.addEventListener("turbo:submit-end", (event) => {
  if (!event.detail.success) {
    // A submission stopped by a newer one (e.g. rapid pagination clicks)
    // carries neither error nor response: ignore it, it's not a failure.
    // Genuine failures always include one of them (TypeError when offline,
    // FetchResponse on HTTP errors).
    const failure = event.detail.error ?? event.detail.fetchResponse;
    if (failure) showHttpError(failure);
    event.preventDefault();
  }
});
