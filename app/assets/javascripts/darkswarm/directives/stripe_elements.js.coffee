Darkswarm.directive "stripeElements", ($injector, StripeElements) ->
  restrict: 'E'
  template: "<div class='card-element'>\
             <label for='card-number-element'>\
             <span>Card number</span>\
             <div id='card-number-element' class='field'></div>\
             </label>\
             <label for='card-expiry-element'>\
             <span>Expiry date</span>\
             <div id='card-expiry-element' class='field'></div>\
             </label>\
             <label for='card-cvc-element'>\
             <span>CVC</span>\
             <div id='card-cvc-element' class='field'></div>\
             <div id='card-errors' class='error'></div>\              
             </label>"

  link: (scope, elem, attr)->
    if $injector.has('stripeObject')
      stripe = $injector.get('stripeObject')

      #hidePostalCode: false
      style = {
        base:
            fontFamily: "Roboto, Arial, sans-serif"
            fontSize: '16px'
            color: '#5c5c5c'
            '::placeholder':
              color: '#6c6c6c'
      }
      cardNumberElement = stripe.elements().create('cardNumber', { style: style })
      cardNumberElement.mount('#card-number-element')
      cardNumberElement.addEventListener 'change', (event) ->
        changeEventHandler(event)

      cardExpiryElement = stripe.elements().create('cardExpiry', { style: style })
      cardExpiryElement.mount('#card-expiry-element')
      cardExpiryElement.addEventListener 'change', (event) ->
        changeEventHandler(event)        

      cardCvcElement = stripe.elements().create('cardCvc', { style: style })
      cardCvcElement.mount('#card-cvc-element')
      cardCvcElement.addEventListener 'change', (event) ->
        changeEventHandler(event)

      changeEventHandler = (event) ->
        displayError = document.getElementById('card-errors')
        if event.error
          displayError.textContent = event.error.message
        else
          displayError.textContent = ''
        return

      StripeElements.stripe = stripe
      #StripeElements.card = card
