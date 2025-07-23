import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["rule", "index"];

  add() {
    const rule_type = this.ruleTarget.value;
    const index = this.indexTarget.value;

    // fetch from backend
    fetch(`tag_rules/new?rule_type=${rule_type}&index=${index}`, {
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
