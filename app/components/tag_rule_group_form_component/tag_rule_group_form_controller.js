import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["customerTag", "ruleCustomerTag"];

  updatePreferredCustomerTag() {
    const customerTag = this.customerTagTarget.value;

    this.ruleCustomerTagTargets.forEach((element) => (element.value = customerTag));
  }
}
