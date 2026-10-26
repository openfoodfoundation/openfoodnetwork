// Display an alert to the user based on the http error
// Accepts a status number, a fetch Response, a Turbo FetchResponse,
// or a fetch error (e.g. TypeError on offline, AbortError on abort).
export default function showHttpError(error) {
  // Ignore aborted fetch requests
  if (error?.name === "AbortError") return;

  // Support legacy call sites passing a status number directly
  let status;
  if (typeof error === "number") {
    status = error;
  } else {
    // Extract status safely from all known shapes.
    // Missing/unknown errors mean the request never got a response
    // (e.g. offline), so they fall through to the network error alert.
    status =
      error?.status ??
      error?.statusCode ??
      error?.response?.status ??
      error?.response?.statusCode ??
      null;
  }

  // Ignore aborted / canceled XHRs
  if (status === 0) return;

  // Note that other 4xx errors (e.g. 403, 404, 422) are handled elsewhere
  // and intentionally do not trigger a generic alert here.
  if (status === 401) {
    alert(I18n.t("errors.unauthorized.message"));
  } else if (status === null || status === undefined) {
    alert(I18n.t("errors.network_error.message"));
  } else if (status >= 500) {
    alert(I18n.t("errors.general_error.message"));
  }
}
