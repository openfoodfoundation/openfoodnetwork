import "@hotwired/turbo";

document.addEventListener("turbo:frame-missing", (event) => {
  // don't replace frame contents
  event.preventDefault();

  // show error message instead
  status = event.detail.response.status;
  if(status == 401) {
    alert(I18n.t("errors.unauthorized.message"));
  } else {
    alert(I18n.t("errors.general_error.message"));
  }
});
