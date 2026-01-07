// Display an alert to the user based on the http error
export default function showHttpError(error) {
  // Ignore completely missing errors
  if (!error) return;

  // Ignore aborted fetch requests
  if (error.name === "AbortError") return;

  // Extract status safely from all known shapes
  const status = error.status ?? error.statusCode ?? error.response?.status ?? null;

  // Ignore aborted / canceled XHRs
  if (status === 0) return;

  // Note that other 4xx errors (e.g. 403, 404, 422) are handled elsewhere
  // and intentionally do not trigger a generic alert here.
  if (status === 401) {
    alert(I18n.t("errors.unauthorized.message"));
  } else if (status === null) {
    alert(I18n.t("errors.network_error.message"));
  } else if (status >= 500) {
    alert(I18n.t("errors.general_error.message"));
  }
}
