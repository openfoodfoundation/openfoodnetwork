import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["rule", "index", "divId", "isDefault", "customerTag"];

  add() {
    console.log(this.divIdTarget.value);
    const rule_type = this.ruleTarget.value;
    const index = this.indexTarget.value;
    const divId = this.divIdTarget.value;
    const isDefault = this.isDefaultTarget.value;
    const customerTags = this.customerTagTarget.value;

    // fetch from backend
    fetch(
      `tag_rules/new?rule_type=${rule_type}&index=${index}&div_id=${divId}&is_default=${isDefault}&customer_tags=${customerTags}`,
      {
        method: "GET",
        headers: {
          Accept: "text/vnd.turbo-stream.html",
        },
      },
    )
      .then((r) => r.text())
      .then((html) => {
        Turbo.renderStreamMessage(html);
        this.indexTarget.value = parseInt(index) + 1;
      })
      .catch((error) => console.warn(error));
  }
}
