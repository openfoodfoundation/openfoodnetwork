// This is what a basic Stimulus Controller looks like. To apply it to an element you can do:
// div{"data-controller": "example"}
// or:
// div{data: {controller: "example"}}

import { Controller } from "stimulus"

export default class extends Controller {
  // connect() is a built-in lifecycle callback for Stimulus Controllers. It fires when the
  // element is loaded on the page, and that also *includes* when some HTML is asynchronously
  // injected into the DOM. This means initialization is not tied to the page load event, but
  // will also happen dynamically if and when new DOM elements are added or removed.
  connect() {
    console.log("We're connected!")
  }
}

// For more info take a look at https://stimulus.hotwired.dev/handbook/introduction
