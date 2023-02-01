import { Controller } from "stimulus";

// UnsavedChanges allows you to promp the user about unsaved changes when trying to leave the page
//
// Usage :
// - with beforeunload event :
//    <form
//      data-controller="unsaved-changes"
//      data-action="beforeunload@window->unsaved-changes#leavingPage"
//      data-unsaved-changes-changed="true"
//    >
//      <input data-action="change->unsaved-changes#formIsChanged" />
//    </form>
//
// - with turbolinks :
//    <form
//      data-controller="unsaved-changes"
//      data-action="turbolinks:before-visit@window->unsaved-changes#leavingPage"
//      data-unsaved-changes-changed="true"
//    >
//      <input data-action="change->unsaved-changes#formIsChanged" />
//    </form>
//
// You can also combine the two actions
// You also need to add 'data-action="change->unsaved-changes#formIsChanged"' on all the form element
// that can be interacted with
//
// Optional, you can add 'data-unsaved-changes-changed="true"' if you want to disable all
// submit buttons when the form hasn't been interacted with
//
export default class extends Controller {
  connect() {
    // disable submit button when first loading the page
    if (!this.isFormChanged() && this.isSubmitButtonDisabled()) {
      this.disableButtons();
    }
  }

  formIsChanged(event) {
    // We only do something if the form hasn't already been changed
    if (!this.isFormChanged()) {
      this.setChanged("true");

      if (this.isSubmitButtonDisabled()) {
        this.enableButtons();
      }
    }
  }

  leavingPage(event) {
    const LEAVING_PAGE_MESSAGE = I18n.t("admin.unsaved_confirm_leave");

    if (this.isFormChanged()) {
      if (event.type == "turbolinks:before-visit") {
        if (!window.confirm(LEAVING_PAGE_MESSAGE)) {
          event.preventDefault();
        }
      } else {
        // We cover our bases, according to the documentation we should be able to prompt the user
        // by calling event.preventDefault(), but it's not really supported yet.
        // Instead we set the value of event.returnValue, and return a string, both of them
        // should prompt the user.
        // Note, in most modern browser a generic string not under the control of the webpage is shown
        // instead of the returned string.
        //
        // More info : https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event
        //
        event.returnValue = LEAVING_PAGE_MESSAGE;
        return event.returnValue;
      }
    }
  }

  setChanged(changed) {
    this.data.set("changed", changed);
  }

  isFormChanged() {
    return this.data.get("changed") == "true";
  }

  isSubmitButtonDisabled() {
    if (this.data.has("disable-submit-button")) {
      return this.data.get("disable-submit-button") == "true";
    }

    return false;
  }

  enableButtons() {
    this.submitButtons().forEach((button) => {
      button.disabled = false;
    });
  }

  disableButtons() {
    this.submitButtons().forEach((button) => {
      button.disabled = true;
    });
  }

  submitButtons() {
    return this.element.querySelectorAll("input[type='submit']");
  }
}
