// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import StimulusReflex from "stimulus_reflex";
import consumer from "../channels/consumer";
import controller from "../controllers/application_controller";
import CableReady from "cable_ready";
import RailsNestedForm from "@stimulus-components/rails-nested-form/dist/stimulus-rails-nested-form.umd.js"; // the default module entry point is broken
import { Autocomplete } from "stimulus-autocomplete";

const application = Application.start();
const context = require.context("controllers", true, /_controller\.js$/);
application.load(definitionsFromContext(context));

// Load component controller, but generate a shorter controller name than "definitionsFromContext" would
//  - for controller in a component subdirectory, get rid of the component folder and use
//    the controller name, ie:
//    ./tag_rule_group_form_component/tag_rule_group_form_controller.js -> tag-rule-group-form
//  - for controller that don't match the pattern above, replace "_" by "-" and "/" by "--", ie:
//    ./vertical_ellipsis_menu/component_controller.js -> vertical-ellipsis-menu--component
//
const contextComponents = require.context("../../components", true, /_controller\.js$/);
contextComponents.keys().forEach((path) => {
  const module = contextComponents(path);

  // Check whether a module has the default export defined
  if (!module.default) return;

  const identifier = path
    .replace(/^\.\//, "")
    .replace(/^\w+_component\//, "")
    .replace(/_controller\.js$/, "")
    .replace(/\//g, "--")
    .replace(/_/g, "-");

  application.register(identifier, module.default);
});

application.register("nested-form", RailsNestedForm);
application.register("autocomplete", Autocomplete);

application.consumer = consumer;
StimulusReflex.initialize(application, { controller, isolate: true });
StimulusReflex.debug = process.env.RAILS_ENV === "development";
CableReady.initialize({ consumer });
