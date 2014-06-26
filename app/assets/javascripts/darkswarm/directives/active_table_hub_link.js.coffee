Darkswarm.directive "activeTableHubLink", (CurrentHub, CurrentOrder) ->
  restrict: "A"
  scope:
    hub: '=activeTableHubLink'
  template: "{{action}}"
  link: (scope, elm, attr)->
    # Swap out the text of the hub link depending on whether it'll change current hub
    # To be used with ofnEmptiesCart
    if CurrentHub.hub?.id and CurrentHub.hub.id isnt scope.hub.id
      scope.action = attr.change
    else
      scope.action = attr.shop
