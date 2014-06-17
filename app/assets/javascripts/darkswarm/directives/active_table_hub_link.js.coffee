Darkswarm.directive "activeTableHubLink", (CurrentHub, CurrentOrder) ->
  restrict: "A"
  scope:
    hub: '=activeTableHubLink'
  template: "{{action}} <strong>{{hub.name}}</strong>"
  link: (scope, elm, attr)->
    # Swap out the text of the hub link depending on whether it'll change current hub
    # To be used with ofnEmptiesCart
    if CurrentHub.id and CurrentHub.id isnt scope.hub.id
      scope.action = attr.change
    else
      scope.action = attr.shop
