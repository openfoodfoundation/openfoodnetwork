Darkswarm.directive "ofnEmptiesCart", (CurrentHub, CurrentOrder, Navigation, storage) ->
  restrict: "A"
  link: (scope, elm, attr)-> 
    hub = scope.$eval(attr.ofnEmptiesCart)
    # A hub is selected, we're changing to a different hub, and the cart isn't empty
    if CurrentHub.hub.id and CurrentHub.hub.id isnt hub.id
      unless CurrentOrder.empty()
        elm.bind 'click', (ev)->
          ev.preventDefault()
          if confirm "Are you sure? This will change your selected Hub and remove any items in you shopping cart."
            storage.clearAll() # One day this will have to be moar GRANULAR
            Navigation.go scope.hub.path 
