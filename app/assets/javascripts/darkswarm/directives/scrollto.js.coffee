Darkswarm.directive "ofnScrollTo", ($location, $anchorScroll)->
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind 'click', (ev)->
      ev.stopPropagation()
      $location.hash attrs.ofnScrollTo 
      $anchorScroll()
