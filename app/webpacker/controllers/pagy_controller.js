import { Controller } from "stimulus";
import Pagy from "js/pagy.mjs";

// Renders the page links of a pagy `series_nav_js` within this element
export default class extends Controller {
  connect() {
    Pagy.init(this.element);
  }
}
