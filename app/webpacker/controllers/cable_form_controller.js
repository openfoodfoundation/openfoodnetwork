import { Controller } from "stimulus";

// In order to send cable-ready requests from forms we need this Stimulus controller. We cannot use
// mrujs to do this because it hooks into data-remote|data-confirm|etc. tags. However the admin
// already uses jquery_ujs which already hooks into these same data-tags so we don't want jquery_ujs
// and mrujs both hooking into these data-tags at the same time.
export default class extends Controller {
  initialize() {
    this.element.setAttribute("data-action", "submit->cable-form#submit");
  }

  submit(e) {
    e.preventDefault();
    window.mrujs
      .fetch(this.element.getAttribute("action"), {
        body: JSON.stringify(this.#parameters()),
        element: this.element,
        headers: {
          Accept: "text/vnd.cable-ready.json",
          "Content-Type": "application/json",
        },
        method: this.#method(),
      })
      .then((data) => {
        return data.json();
      })
      .then((operation) => {
        CableReady.perform(operation);
      })
      .catch((error) => console.error(error));
  }

  // private

  // https://gist.github.com/rajibkuet07/27360a8ee742ee3e2f25fb5dcac29b8c
  #formToObject(form) {
    let object = {};
    new FormData(form).forEach((value, key) => {
      if (key.includes("[")) {
        const keys = key.split(/[\[\]]+/).filter((k) => k.length > 0);
        let obj = object;
        for (let i = 0; i < keys.length; i++) {
          const currentKey = keys[i];
          if (!obj[currentKey]) {
            if (i === keys.length - 1) {
              obj[currentKey] = value;
            } else {
              obj[currentKey] = isNaN(keys[i + 1]) ? {} : [];
            }
          }
          obj = obj[currentKey];
        }
      } else {
        object[key] = value;
      }
    });
    return object;
  }

  #method() {
    return (
      this.#parameters()._method || this.element.getAttribute("method")
    ).toUpperCase();
  }

  #parameters() {
    return this.#formToObject(this.element);
  }
}
