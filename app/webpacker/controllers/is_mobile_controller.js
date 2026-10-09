import { Controller } from "stimulus";

// Toggles `.is-mobile` on the <body> on small screens.
// Driven from JS, not a media query, because admin has no viewport meta tag so a
// media query never matches on a real phone (it reports the ~980px layout viewport).
export default class extends Controller {
  static values = { maxWidth: { type: Number, default: 500 } };

  connect() {
    this.update = this.update.bind(this);
    this.update();
    window.addEventListener("resize", this.update);
  }

  disconnect() {
    window.removeEventListener("resize", this.update);
  }

  update() {
    // screen.width reflects the physical device width; innerWidth catches a narrow
    // desktop window. The smaller of the two handles both.
    const width = Math.min(window.innerWidth, window.screen.width);
    document.body.classList.toggle("is-mobile", width <= this.maxWidthValue);
  }
}
