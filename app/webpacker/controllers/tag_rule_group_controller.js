import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["index", "customerRuleIndex"];

  add(e) {
    e.preventDefault();
    const index = this.indexTarget.value;
    const customerRuleIndex = this.customerRuleIndexTarget.value;

    // fetch from backend
    fetch(`new_tag_rule_group?index=${index}&customer_rule_index=${customerRuleIndex}`, {
      method: "GET",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
      },
    })
      .then((r) => r.text())
      .then((html) => {
        Turbo.renderStreamMessage(html);
        this.indexTarget.value = parseInt(index) + 1;
      })
      .catch((error) => console.warn(error));
  }
}
