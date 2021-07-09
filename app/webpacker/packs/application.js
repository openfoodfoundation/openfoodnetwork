/* eslint no-console:0 */

// StimulusJS
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

const application = Application.start();
const context = require.context("controllers", true, /.js$/);
application.load(definitionsFromContext(context));

// Add tailwind CSS
import "./application.scss";
