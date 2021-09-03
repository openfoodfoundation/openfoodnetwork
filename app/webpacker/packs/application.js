/* eslint no-console:0 */

// StimulusJS
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import "./application.scss"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))
