import { Controller } from "stimulus";

// Since Rails 7 it adds "data-disabled-with" property to submit, you'll need to add
// 'data-disable-with="false' for this to function as expected, ie:
//
//    <input id="test-submit" type="submit" data-disable-with="false" data-toggle-button-disabled-target="button"/>
//
export default class extends Controller {
  static targets = ["button"];

  connect() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true;
    }
  }

  inputIsChanged(e) {
    if (e.target.value !== "") {
      this.buttonTarget.disabled = false;
    } else {
      this.buttonTarget.disabled = true;
    }
  }
}
