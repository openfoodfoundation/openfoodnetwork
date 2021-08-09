angular.module('Darkswarm').directive "ofnScrollTo", ($location, $anchorScroll)->
  # Onclick sets $location.hash to attrs.ofnScrollTo
  # Then triggers anchorScroll
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind 'click', (ev)->
      ev.stopPropagation()
      $location.hash attrs.ofnScrollTo 
      $anchorScroll()
