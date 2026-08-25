import "@hotwired/turbo";
import showHttpError from "./services/show_http_error";

import TurboPower from "turbo_power";
TurboPower.initialize(Turbo.StreamActions);

document.addEventListener("turbo:frame-missing", (event) => {
  event.preventDefault();
  const status = event.detail.response?.status;
  if (status && status >= 400) {
    showHttpError(status);
  } else {
    event.detail.visit(event.detail.response);
  }
});

document.addEventListener("turbo:submit-end", (event) => {
  if (!event.detail.success) {
    // show error message on failure
    showHttpError(event.detail.fetchResponse?.statusCode);
    event.preventDefault();
  }
});

document.addEventListener("turbo:load", () => {
  if (typeof jQuery !== "undefined" && typeof jQuery.fn.select2 === "function") {
    jQuery("select.select2").each(function () {
      if (!jQuery(this).data("select2")) {
        jQuery(this).select2({ allowClear: true });
      }
    });
  }
});
