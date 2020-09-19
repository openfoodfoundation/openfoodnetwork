class Element {
  mount(el) {
    if (typeof el === "string") {
      el = document.querySelector(el);
    }

    el.classList.add('StripeElement');

    el.innerHTML = `
      <input id="stripe-cardnumber" name="cardnumber" placeholder="Card number" size="16" type="text">
      <input name="exp-date" placeholder="MM / YY" size="6" type="text">
      <input name="cvc" placeholder="CVC" size="3" type="text">
    `;
  }

  addEventListener(event) {
    return true;
  }
}

window.Stripe = () => {
  const fetchLastFour = () => {
    return document.getElementById("stripe-cardnumber").value.substr(-4, 4);
  };

  return {
    createPaymentMethod: () => {
      return new Promise(resolve => {
        resolve({
          paymentMethod: {
            id: "pm_123",
            card: {
              brand: 'visa',
              last4: fetchLastFour(),
              exp_month: "10",
              exp_year: "2050"
            }
          }
        });
      });
    },

    elements: () => {
      return {
        create: (type, options) => new Element()
      };
    },

    createToken: card => {
      return new Promise(resolve => {
        resolve({ token: { id: "tok_123", card: { last4: fetchLastFour() } } });
      });
    }
  };
};
