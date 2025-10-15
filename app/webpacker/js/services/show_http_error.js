// Display an alert to the user based on the http status

export default function showHttpError(status) {
  // Note that other 4xx errors will be handled differently.
  if (status == 401) {
    alert(I18n.t("errors.unauthorized.message"));
  } else if (status === undefined) {
    alert(I18n.t("errors.network_error.message"));
  } else if (status >= 500) {
    alert(I18n.t("errors.general_error.message"));
  }
}
