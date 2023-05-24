import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

const application = Application.start();
const context = require.context("controllers", true, /.js$/);
application.load(definitionsFromContext(context));

import StimulusReflex from "stimulus_reflex";
import consumer from "../channels/consumer";
import controller from "../controllers/application_controller";

application.consumer = consumer;
StimulusReflex.initialize(application, { controller, isolate: true });
StimulusReflex.debug = process.env.RAILS_ENV === "development";
CableReady.initialize({ consumer });

import debounced from "debounced";
debounced.initialize({ input: { wait: 300 } });

import Trix from "trix";
