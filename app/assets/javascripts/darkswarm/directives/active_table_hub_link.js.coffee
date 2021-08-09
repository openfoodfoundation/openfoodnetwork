angular.module('Darkswarm').directive "activeTableHubLink", (CurrentHub, CurrentOrder) ->
  # Change the text of the hub link based on CurrentHub
  # To be used with ofnEmptiesCart
  # Takes "change" and "shop" as text string attributes
  restrict: "A"
  scope:
    hub: '=activeTableHubLink'
  template: "{{action}}"
  link: (scope, elm, attr)->
    if CurrentHub.hub?.id and CurrentHub.hub.id isnt scope.hub.id
      scope.action = attr.change
    else
      scope.action = attr.shop
