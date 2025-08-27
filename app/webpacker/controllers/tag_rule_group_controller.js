import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["index", "customerRuleIndex"];

  add(e) {
    e.preventDefault();
    const index = this.indexTarget.value;
    const customerRuleIndex = this.customerRuleIndexTarget.value;

    // fetch from backend
    const params = new URLSearchParams();
    params.append("index", index);
    params.append("customer_rule_index", customerRuleIndex);

    fetch(`new_tag_rule_group?${params}`, {
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
