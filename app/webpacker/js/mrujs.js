import CableReady from "cable_ready";
import mrujs from "mrujs";
import { CableCar } from "mrujs/plugins";

mrujs.start({
  plugins: [new CableCar(CableReady, { mimeType: "text/vnd.cable-ready.json" })],
});

document.addEventListener("ajax:beforeSend", (event) => {
  window.Turbo.navigator.adapter.progressBar.setValue(0);
  window.Turbo.navigator.adapter.progressBar.show();
});

document.addEventListener("ajax:complete", (event) => {
  window.Turbo.navigator.adapter.progressBar.setValue(100);
  window.Turbo.navigator.adapter.progressBar.hide();
});
