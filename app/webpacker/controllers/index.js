// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import StimulusReflex from "stimulus_reflex";
import consumer from "../channels/consumer";
import controller from "../controllers/application_controller";
import CableReady from "cable_ready";
import NestedForm from 'stimulus-rails-nested-form/dist/stimulus-rails-nested-form.umd.js' // the default module entry point is broken


const application = Application.start();
const context = require.context("controllers", true, /_controller\.js$/);
const contextComponents = require.context("../../components", true, /_controller\.js$/);

application.load(definitionsFromContext(context).concat(definitionsFromContext(contextComponents)));
application.register('nested-form', NestedForm);
application.consumer = consumer;
StimulusReflex.initialize(application, { controller, isolate: true });
StimulusReflex.debug = process.env.RAILS_ENV === "development";
CableReady.initialize({ consumer });
