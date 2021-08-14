/* eslint no-console:0 */

// StimulusJS
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))

import mrujs from "mrujs"
import * as Turbo from "@hotwired/turbo"

window.Turbo = Turbo
mrujs.start()
