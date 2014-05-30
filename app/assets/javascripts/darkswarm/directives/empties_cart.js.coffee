Darkswarm.directive "ofnEmptiesCart", (CurrentHub, CurrentOrder, Navigation) ->
  restrict: "A"
  scope:
    hub: '=ofnEmptiesCart'
  template: "{{action}} <strong>{{hub.name}}</strong>"
  link: (scope, elm, attr)-> 
    # A hub is selected, we're changing to a different hub, and the cart isn't empty
    if CurrentHub.id and CurrentHub.id isnt scope.hub.id and not CurrentOrder.empty()
      scope.action = attr.change
      elm.bind 'click', (ev)->
        ev.preventDefault()
        if confirm "Are you sure? This will change your selected Hub and remove any items in you shopping cart."
          Navigation.go scope.hub.path 
    else
      scope.action = attr.shop
