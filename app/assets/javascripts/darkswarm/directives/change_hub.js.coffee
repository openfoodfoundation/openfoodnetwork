angular.module('Darkswarm').directive "ofnChangeHub", (CurrentHub, Cart) ->
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
        if confirm t('confirm_hub_change')
          Cart.clear()
        else
          ev.preventDefault()
