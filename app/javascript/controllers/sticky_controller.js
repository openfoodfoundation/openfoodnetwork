import { Controller } from "stimulus";

// This add a `sticked` class to the element (`container`) when the user scrolls down
// or up until the element is `sticked`.
// The class is then removed once the element is no more `sticked`.
// The element should have a `data-sticky-target` attribute with `container` as value.
// This is only functionnal with a sticked element at the bottom. We could improve that point
// by adding a `data-position` attribute with `top|bottom|left|right` as value and
// modify the code below to handle the different positions.
export default class extends Controller {
  static targets = ["container"];

  connect() {
    this.containerTarget.style.position = "sticky";
    this.containerTarget.style.bottom = "-1px";
    const observer = new IntersectionObserver(
      ([e]) => {
        e.target.classList.toggle("sticked", e.intersectionRatio < 1);
      },
      { threshold: [1] }
    );
    observer.observe(this.containerTarget);
  }
}
