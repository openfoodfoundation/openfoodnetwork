import { Controller } from "stimulus";
import showHttpError from "../../webpacker/js/services/show_http_error";

export default class extends Controller {
  static targets = ["rule", "ruleCustomerTag"];
  static values = { index: Number };

  add({ params }) {
    const rule_type = this.ruleTarget.value;
    const index = this.indexValue;
    const divId = params["divId"];
    const isDefault = params["isDefault"];
    const customerTags = this.hasRuleCustomerTagTarget
      ? this.ruleCustomerTagTarget.value
      : undefined;

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
      .then((response) => {
        if (!response.ok) {
          showHttpError(response.status);
          throw response;
        }
        return response.text();
      })
      .then((html) => {
        Turbo.renderStreamMessage(html);
        this.indexValue = parseInt(index) + 1;
      })
      .catch((error) => console.error(error));
  }
}
