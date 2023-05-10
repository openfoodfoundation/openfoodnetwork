import "controllers";
import "channels";

import "@hotwired/turbo";
import CableReady from "cable_ready";
import mrujs from "mrujs";
import { CableCar } from "mrujs/plugins";

mrujs.start({
  plugins: [new CableCar(CableReady, { mimeType: "text/vnd.cable-ready.json" })],
});

import debounced from "debounced";
debounced.initialize({ input: { wait: 300 } });
