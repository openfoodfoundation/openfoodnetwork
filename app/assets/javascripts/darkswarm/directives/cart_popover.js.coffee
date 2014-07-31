Darkswarm.directive "cart", ->
  # Toggles visibility of the "cart" popover
  restrict: 'A'
  link: (scope, elem, attr)->
    scope.open = false
    elem.bind 'click', ->
      scope.$apply ->
        scope.open = !scope.open
