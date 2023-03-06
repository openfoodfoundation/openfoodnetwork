import { Controller } from "stimulus";

// Handles form elements for selecting previously saved Stripe cards from a list of cards

export default class extends Controller {
  static targets = ["stripeelements", "select"];

  connect() {
    this.initSelectedCard();
    document.addEventListener("stripecards:initSelectedCard", (e) => {
      if (e.detail == this.element.dataset.paymentmethodId) {
        this.initSelectedCard();
      }
    });
  }

  initSelectedCard() {
    if (this.hasSelectTarget) {
      this.selectCard(this.selectTarget.value);
    }
  }

  onSelectCard(event) {
    this.selectCard(event.target.value);
  }

  selectCard(cardValue) {
    if (cardValue == "") {
      this.stripeelementsTarget.style.display = "block";
      this.getFormElementsArray(this.stripeelementsTarget).forEach((i) => {
        i.disabled = false;
      });
    } else {
      this.stripeelementsTarget.style.display = "none";
      this.getFormElementsArray(this.stripeelementsTarget).forEach((i) => {
        i.disabled = true;
      });
    }
  }

  getFormElementsArray(container) {
    return Array.from(container.querySelectorAll("input, select, textarea"));
  }
}
