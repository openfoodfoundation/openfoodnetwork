angular.module("ofn.admin").directive "enterToSubmit", ->
  restrict: 'A'

  link: (scope, element, attrs) ->
    element.bind "keypress", (event) ->
      return if event.which != 13

      scope.submit()
