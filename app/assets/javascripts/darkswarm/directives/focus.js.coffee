Darkswarm.directive "ofnFocus", ->
  restrict: "A"
  link: (scope, element, attrs) ->
    scope.$watch attrs.ofnFocus, ((focus) ->
      console.log focus
      focus and element.focus()
      return
    ), true

    return

