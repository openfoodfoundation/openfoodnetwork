import { Controller } from "stimulus";
import { locationPathName } from "js/window_location_wrapper";

// This is meant to be used with the "modal:closing" event, ie:
//
//  <div data-controller="out-of-stock-modal"
//       data-action="moda:closing@out-of-stock-modal#redirect"
//       data-out-of-stock-modal-redirect-value="true"
//  >
//  </div>
//
export default class extends Controller {
  static values = { redirect: { type: Boolean, default: false } };

  redirect() {
    if (this.redirectValue) {
      locationPathName("/shop");
    }
  }
}
