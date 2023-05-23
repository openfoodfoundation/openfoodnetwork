/* eslint no-console:0 */
import CableReady from "cable_ready";
import mrujs from "mrujs";
import { CableCar } from "mrujs/plugins";
import * as Turbo from "@hotwired/turbo";

window.Turbo = Turbo;
window.CableReady = CableReady;
mrujs.start({
  plugins: [new CableCar(CableReady, { mimeType: "text/vnd.cable-ready.json" })],
});

require.context("../fonts", true);
const images = require.context("../images", true);
const imagePath = (name) => images(name, true);

import "controllers";

document.addEventListener("turbo:visit", (event) => {
  window._mtm?.push({ event: "mtm.PageView" });
});
