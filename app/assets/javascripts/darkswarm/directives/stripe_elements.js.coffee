Darkswarm.directive "stripeElements", ($injector, StripeElements) ->
  restrict: 'E'
  template: "<label for='card-element'>\
             <div id='card-element'></div>\
             <div id='card-errors' class='error'></div>\
             </label>"

  link: (scope, elem, attr)->
    if $injector.has('stripeObject')
      stripe = $injector.get('stripeObject')

      card = stripe.elements().create 'card',
        hidePostalCode: false
        style:
          base:
            fontFamily: "Roboto, Arial, sans-serif"
            fontSize: '16px'
            color: '#4c4c4c'
            '::placeholder':
              color: '#6c6c6c'
      card.mount('#card-element')

      # Elements validates user input as it is typed. To help your customers
      # catch mistakes, you should listen to change events on the card Element
      # and display any errors:
      card.addEventListener 'change', (event) ->
        displayError = document.getElementById('card-errors')
        if event.error
          displayError.textContent = event.error.message
        else
          displayError.textContent = ''
        return

      StripeElements.stripe = stripe
      StripeElements.card = card
