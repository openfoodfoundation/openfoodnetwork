Darkswarm.directive "ofnScrollTo", ($location, $anchorScroll)->
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind 'click', ->
      $location.hash attrs.ofnScrollTo 
      $anchorScroll()
