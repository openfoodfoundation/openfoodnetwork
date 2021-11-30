import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "cardElement", "cardErrors", "responseToken" ];
  static styles = {
    base: {
      fontFamily: "Roboto, Arial, sans-serif",
      fontSize: "16px",
      color: "#5c5c5c",
      "::placeholder": {
        color: "#6c6c6c"
      }
    }
  };

  connect() {
    const stripe = Stripe(this.data.get("key"));
    const elements = stripe.elements();
    const form = this.responseTokenTarget.form;
    const error_container = this.cardErrorsTarget;
    const token_field = this.responseTokenTarget;

    const stripe_element = elements.create("card", {
      style: this.constructor.styles,
      hidePostalCode: true
    });

    // Mount Stripe Elements JS to the field and add form validations
    stripe_element.mount(this.cardElementTarget);
    stripe_element.addEventListener("change", function (event) {
      if (event.error) {
        error_container.textContent = event.error.message;
      } else {
        error_container.textContent = "";
      }
    });

    // Before the form is submitted we send the card details directly to Stripe (via StripeJS),
    // and receive a token which represents the card object, and add that token into the form.
    form.addEventListener("submit", function (event) {
      event.preventDefault();

      stripe.createPaymentMethod({type: "card", card: stripe_element}).then(function (response) {
        if (response.error) {
          error_container.textContent = response.error.message;
        } else {
          token_field.setAttribute("value", response.paymentMethod.id);
          form.submit();
        }
      });
    });
  }
}
