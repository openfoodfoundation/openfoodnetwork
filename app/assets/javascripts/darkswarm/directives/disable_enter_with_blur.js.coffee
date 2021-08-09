angular.module('Darkswarm').directive "disableEnterWithBlur", ()->
  # Stops enter from doing normal enter things, and blurs the input
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind "keydown keypress", (e)->
      code = e.keyCode || e.which
      if code == 13
        element.blur()
        e.preventDefault()
