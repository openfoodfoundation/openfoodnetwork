Darkswarm.directive "ofnEmptiesCart", (CurrentHub, Navigation) ->
  restrict: "A"
  scope:
    hub: '=ofnEmptiesCart'
  template: "{{action}} <strong>{{hub.name}}</strong>"
  link: (scope, elm, attr)-> 
    if CurrentHub.id and CurrentHub.id isnt scope.hub.id
      scope.action = attr.change
      elm.bind 'click', (ev)->
        ev.preventDefault()
        if confirm "Are you sure? This will change your selected Hub and remove any items in you shopping cart."
          Navigation.go scope.hub.path 
    else
      scope.action = attr.shop


