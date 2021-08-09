angular.module('Darkswarm').directive "ofnDisableScroll", ()->
  # Stops scrolling from incrementing or decrementing input value
  # Useful for number inputs
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind 'focus', ->
      element.bind 'mousewheel', (e)->
        e.preventDefault()
    element.bind 'blur', ->
      element.unbind 'mousewheel'
