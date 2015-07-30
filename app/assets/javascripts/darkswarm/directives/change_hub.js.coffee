Darkswarm.directive "ofnChangeHub", (CurrentHub, Cart) ->
  # Compares scope.hub with CurrentHub. Will trigger an confirmation if they are different,
  # and Cart isn't empty
  restrict: "A"
  scope:
    hub: "=ofnChangeHub"
  link: (scope, elm, attr)->
    cart_will_need_emptying = ->
      CurrentHub.hub?.id and CurrentHub.hub.id isnt scope.hub.id and !Cart.empty()

    if cart_will_need_emptying()
      elm.bind 'click', (ev)->
        if confirm "Are you sure? This will change your selected hub and remove any items in your shopping cart."
          Cart.clear()
        else
          ev.preventDefault()
