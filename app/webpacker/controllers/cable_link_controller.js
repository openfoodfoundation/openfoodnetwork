import { Controller } from "stimulus";

// In order to send cable-ready requests from links we need this Stimulus controller. We cannot use
// mrujs to do this because it hooks into data-remote|data-confirm|etc. tags. However the admin
// already uses jquery_ujs which already hooks into these same data-tags so we don't want jquery_ujs
// and mrujs both hooking into these data-tags at the same time.
export default class extends Controller {
  initialize() {
    this.element.setAttribute("data-action", "click->cable-link#click");
  }

  click(e) {
    e.preventDefault();
    this.href = this.element.getAttribute("href");
    fetch(this.href, {
      headers: { "Content-type": "application/vnd.cable-ready.json, */*" },
    })
      .then((data) => data.json())
      .then((operation) => {
        CableReady.perform(operation);
      });
  }
}
