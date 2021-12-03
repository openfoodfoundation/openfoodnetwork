angular.module('admin.payments').directive "stripeElements", ($injector, AdminStripeElements) ->
  restrict: 'E'
  template: "<div >\
             <div class='card-element'></div>\
             <div class='error card-errors'></div>\
             </div>"
  scope:
    selected: "="
  
  link: (scope, elem, attr)->
    if $injector.has('stripeObject')
      stripe = $injector.get('stripeObject')

      card = stripe.elements().create 'card',
        hidePostalCode: false
        style:
          base:
            fontFamily: "Roboto, Arial, sans-serif"
            fontSize: '16px'
            color: '#5c5c5c'
            '::placeholder':
              color: '#6c6c6c'
      card.mount(elem.find('.card-element').get(0))

      # Elements validates user input as it is typed. To help your customers
      # catch mistakes, you should listen to change events on the card Element
      # and display any errors:
      card.addEventListener 'change', (event) ->
        displayError = elem.find('.card-errors').get(0)
        if event.error
          displayError.textContent = event.error.message
        else
          displayError.textContent = ''

        return

      scope.$watch "selected", (value) ->
        if (value)
          AdminStripeElements.stripe = stripe
          AdminStripeElements.card = card 
