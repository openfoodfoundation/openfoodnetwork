angular.module('Darkswarm').directive "ofnDisableEnter", ()->
  # Stops enter from doing normal enter things
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind "keydown keypress", (e)->
      code = e.keyCode || e.which
      if code == 13
        e.preventDefault()
