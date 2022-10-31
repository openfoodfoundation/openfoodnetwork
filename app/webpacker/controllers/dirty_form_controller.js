import ApplicationController from "./application_controller";
const LEAVING_PAGE_MESSAGE = "Are you sure you want to leave?";
const TRACKED_TAGS = ["input", "textarea", "select"];

export default class extends ApplicationController {
  static values = { dirty: Boolean };
  static targets = ["submitBtn"];

  connect() {
    this.trackedTargets = [];
    this.trackChanges();
    // find all anchor tags that link locally
    // and ask confirmation when they are clicked
    this.localLinks = document.querySelectorAll("a[href^='#']");
    this.localLinks.forEach((el) => {
      let boundFunc = this.leavingPage.bind(this);
      el.addEventListener("click", boundFunc);
    });
  }

  makeDirty() {
    this.dirtyValue = true;
  }

  leavingPage(event) {
    if (this.dirtyValue) {
      let confirmation = confirm(LEAVING_PAGE_MESSAGE);
      if (!confirmation) {
        event.preventDefault();
      }
    }
  }

  trackChanges() {
    TRACKED_TAGS.forEach((tag) => {
      let targets = document.getElementsByTagName(tag);
      this.trackedTargets.push(...targets);
    });

    this.trackedTargets.forEach((target) => {
      target.addEventListener("change", this.makeDirty.bind(this));
    });
  }

  dirtyValueChanged() {
    // enable submit button if there is a target and
    // the form is dirty
    if (this.hasSubmitBtnTarget) {
      if (this.dirtyValue) this.submitBtnTarget.removeAttribute("disabled");
    }
  }

  allowFormSubmission(event) {
    this.dirtyValue = false;
  }

  disconnect() {
    this.trackedTargets.forEach((input) =>
      input.removeEventListener("change", this.makeDirty)
    );
    this.localLinks.forEach((el) =>
      el.removeEventListener("click", this.leavingPage)
    );
  }
}
