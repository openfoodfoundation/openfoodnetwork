// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import consumer from "../channels/consumer";
import RailsNestedForm from '@stimulus-components/rails-nested-form/dist/stimulus-rails-nested-form.umd.js' // the default module entry point is broken

const application = Application.start();
const context = require.context("controllers", true, /_controller\.js$/);
const contextComponents = require.context("../../components", true, /_controller\.js$/);

application.load(definitionsFromContext(context).concat(definitionsFromContext(contextComponents)));
application.register('nested-form', RailsNestedForm);

application.consumer = consumer;
 
