# This is a workaround for IE11, which doesn't delete placeholder values
# correctly when an element is focused (when Angular is also used).
Darkswarm.directive "ofnSelectOnFocus", () ->
  restrict: 'A'
  link: (scope, elem, attr) ->
    elem.bind('focus', ->
        elem.select()
      )
