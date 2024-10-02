import "@hotwired/turbo";

import TurboPower from "turbo_power";
TurboPower.initialize(Turbo.StreamActions);

document.addEventListener("turbo:frame-missing", (event) => {
  // don't replace frame contents
  event.preventDefault();

  // show error message instead
  showError(event.detail.response?.status);
});

document.addEventListener("turbo:submit-end", (event) => {
  if (!event.detail.success){
    // show error message on failure
    showError(event.detail.fetchResponse?.statusCode);
    event.preventDefault();
  }
});

function showError(status) {
  if(status == 401) {
    alert(I18n.t("errors.unauthorized.message"));
  } else if(status === undefined) {
    alert(I18n.t("errors.network_error.message"));
  } else {
    alert(I18n.t("errors.general_error.message"));
  }
}
