import { Controller } from "stimulus";

export default class extends Controller {
  moveSelectors = [
    ".off-canvas-wrap .inner-wrap",
    ".off-canvas-wrap .inner-wrap .fixed",
    ".off-canvas-fixed .top-bar",
    ".off-canvas-fixed ofn-flash",
    ".off-canvas-fixed nav.tab-bar",
    ".off-canvas-fixed .page-alert",
  ];

  connect() {
    // Wait a moment after page load before showing the alert. Otherwise we often miss the
    // start of the animation.
    setTimeout(this.#show, 1000);
  }

  close() {
    this.#moveElements().forEach((element) => {
      element.classList.remove("move-up");
    });
  }

  // private

  #moveElements() {
    return document.querySelectorAll(this.moveSelectors.join(","));
  }

  #show = () => {
    this.#moveElements().forEach((element) => {
      element.classList.add("move-up");
    });
  };
}
