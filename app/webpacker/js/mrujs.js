import CableReady from "cable_ready";
import mrujs from "mrujs";
import { CableCar } from "mrujs/plugins";

mrujs.start({
  plugins: [new CableCar(CableReady, { mimeType: "text/vnd.cable-ready.json" })],
});

// Handle legacy jquery ujs buttons
document.addEventListener("ajax:beforeNavigation", (event) => {
  if (event.detail.element.dataset.ujsNavigate !== "false") return;

  event.preventDefault();

  if (event.detail.fetchResponse.response.redirected) {
    document.location.href = event.detail.fetchResponse.response.url;
  }
});

document.addEventListener("ajax:beforeSend", (event) => {
  window.Turbo.navigator.adapter.progressBar.setValue(0);
  window.Turbo.navigator.adapter.progressBar.show();
});

document.addEventListener("ajax:complete", (event) => {
  window.Turbo.navigator.adapter.progressBar.setValue(100);
  window.Turbo.navigator.adapter.progressBar.hide();
});
