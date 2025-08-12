import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["rule", "index", "divId", "isDefault", "customerTag"];

  add() {
    const rule_type = this.ruleTarget.value;
    const index = this.indexTarget.value;
    const divId = this.divIdTarget.value;
    const isDefault = this.isDefaultTarget.value;
    const customerTags = this.hasCustomerTagTarget ? this.customerTagTarget.value : undefined;

    const urlParams = new URLSearchParams();
    urlParams.append("rule_type", rule_type);
    urlParams.append("index", index);
    urlParams.append("div_id", divId);
    urlParams.append("is_default", isDefault);
    if (customerTags != undefined) {
      urlParams.append("customer_tags", customerTags);
    }

    // fetch from backend
    fetch(`tag_rules/new?${urlParams}`, {
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
