Darkswarm.directive "ofnEmptiesCart", (CurrentHub, Cart, Navigation, storage) ->
  # Compares scope.hub with CurrentHub. Will trigger an confirmation if they are different,
  # and Cart isn't empty
  restrict: "A"
  scope:
    hub: "=ofnEmptiesCart"
  link: (scope, elm, attr)-> 
    if CurrentHub.hub?.id and CurrentHub.hub.id isnt scope.hub.id and !Cart.empty()
      elm.bind 'click', (ev)->
        ev.preventDefault()
        if confirm "Are you sure? This will change your selected Hub and remove any items in you shopping cart."
          storage.clearAll() # One day this will have to be moar GRANULAR
          Navigation.go scope.hub.path 
