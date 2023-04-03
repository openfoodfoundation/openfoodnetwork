/* eslint no-console:0 */
import CableReady from "cable_ready";
import mrujs from "mrujs";
import { CableCar } from "mrujs/plugins";
import * as Turbo from "@hotwired/turbo";

window.Turbo = Turbo;
window.CableReady = CableReady;
mrujs.start({
  plugins: [new CableCar(CableReady)],
});

require.context("./fonts", true);
const images = require.context("./images", true);
const imagePath = (name) => images(name, true);

import "./controllers";
