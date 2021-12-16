import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "cardElement", "cardErrors", "expMonth", "expYear", "brand", "last4", "pmId", "stripeElementsForm" ];
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
    const form = this.pmIdTarget.form;
    const error_container = this.cardErrorsTarget;
    const exp_month_field = this.expMonthTarget;
    const exp_year_field = this.expYearTarget;
    const brand_field = this.brandTarget;
    const last4_field = this.last4Target;
    const pm_id_field = this.pmIdTarget;
    const stripeElementsForm = this.stripeElementsFormTarget;

    const stripe_element = elements.create("card", {
      style: this.constructor.styles,
      hidePostalCode: true
    });

    // Mount Stripe Elements JS to the field and add form validations
    stripe_element.mount(this.cardElementTarget);
    stripe_element.addEventListener("change", event => {
      if (event.error) {
        error_container.textContent = event.error.message;
      } else {
        error_container.textContent = "";
      }
    });

    // Before the form is submitted we send the card details directly to Stripe (via StripeJS),
    // and receive a token which represents the card object, and add that token into the form.
    form.addEventListener("submit", event => {
      if (this.isVisible(stripeElementsForm)) {
        event.preventDefault();
        event.stopPropagation();
       
        stripe.createPaymentMethod({type: "card", card: stripe_element}).then(response => {
          if (response.error) {
            error_container.textContent = response.error.message;
          } else {
            pm_id_field.setAttribute("value", response.paymentMethod.id);
            exp_month_field.setAttribute("value", response.paymentMethod.card.exp_month);
            exp_year_field.setAttribute("value", response.paymentMethod.card.exp_year);
            brand_field.setAttribute("value", response.paymentMethod.card.brand);
            last4_field.setAttribute("value", response.paymentMethod.card.last4);

            form.submit();
          }
        });
      }
    });
  }

  isVisible(element) {
    while (element) {
      if (window.getComputedStyle(element).display === "none") {
        return false;
      }
      element = element.parentElement;
    }
    return true;
  }

}
