angular.module('Darkswarm').directive "ofnFocus", ->
  # Takes an expression attrs.ofnFocus
  # Watches value of expression, triggers element.focus() when value is truthy
  # Used to automatically focus on specific inputs in various circumstances
  restrict: "A"
  link: (scope, element, attrs) ->
    scope.$watch attrs.ofnFocus, ((focus) ->
      focus and element.focus()
    ), true
