Darkswarm.directive "cartToggle", ($document) ->
  # Toggles visibility of the "cart" popover
  restrict: 'A'
  link: (scope, elem, attr)->
    scope.open = false

    $document.bind 'click', (event) ->
      cart_button = elem[0]
      element_and_parents = [event.target, event.target.parentElement, event.target.parentElement.parentElement]
      cart_button_clicked = (element_and_parents.indexOf(cart_button) != -1)

      if cart_button_clicked
        scope.$apply ->
          scope.open = !scope.open
      else
        scope.$apply ->
          scope.open = false

      return
