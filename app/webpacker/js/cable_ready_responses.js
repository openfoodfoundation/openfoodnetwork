import CableReady from "cable_ready";

const cableReadyMimeType = "text/vnd.cable-ready.json";

// The mrujs CableCar plugin requested the cable-ready MIME type for remote
// form submissions and performed the CableReady operations in the response.
// Turbo Drive now handles those submissions, so we replicate that behaviour.
//
// The Accept header is only added to form submissions, which covers both real
// forms and the hidden forms Turbo builds for data-turbo-method links. Plain
// navigation and turbo-frames keep the default Accept so request.format on the
// server is unchanged.
document.addEventListener("turbo:before-fetch-request", (event) => {
  if (!(event.target instanceof HTMLFormElement)) return;

  const { fetchOptions } = event.detail;
  const currentAccept = fetchOptions.headers?.Accept;
  if (!currentAccept || currentAccept.includes(cableReadyMimeType)) return;

  fetchOptions.headers = {
    ...fetchOptions.headers,
    Accept: `${cableReadyMimeType}, ${currentAccept}`,
  };
});

// When the server responds with cable-ready operations, let CableReady run
// them instead of letting Turbo render the response.
document.addEventListener("turbo:before-fetch-response", async (event) => {
  const { fetchResponse } = event.detail;
  if (!fetchResponse.contentType?.includes(cableReadyMimeType)) return;

  event.preventDefault();
  await CableReady.perform(await fetchResponse.response.json());
});
