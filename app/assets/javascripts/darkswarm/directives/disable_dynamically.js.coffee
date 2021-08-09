# Allows disabling of link buttons via disabled attribute.
# This is normally ignored, ie the link appears disabled but is still clickable.

angular.module('Darkswarm').directive "disableDynamically", ->
  restrict: 'A'

  link: (scope, element, attrs) ->
    element.on 'click', (e) ->
      if attrs.disabled
        e.preventDefault()
      return

    scope.$on "$destroy", ->
      element.off("click")
