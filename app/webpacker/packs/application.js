/* eslint no-console:0 */

// StimulusJS
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

const application = Application.start();
const context = require.context("controllers", true, /.js$/);
application.load(definitionsFromContext(context));

import CableReady from "cable_ready";
import mrujs from "mrujs";
import { CableCar } from "mrujs/plugins";
import * as Turbo from "@hotwired/turbo";

window.Turbo = Turbo;
window.CableReady = CableReady;
mrujs.start({
  plugins: [new CableCar(CableReady)],
});

require.context("../fonts", true);
const images = require.context("../images", true);
const imagePath = (name) => images(name, true);

import StimulusReflex from "stimulus_reflex";
import consumer from "../channels/consumer";
import controller from "../controllers/application_controller";

application.consumer = consumer;
StimulusReflex.initialize(application, { controller, isolate: true });
StimulusReflex.debug = process.env.RAILS_ENV === "development";
CableReady.initialize({ consumer });
