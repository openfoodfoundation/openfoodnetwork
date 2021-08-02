angular.module('Darkswarm').directive 'scrollAfterLoad', ($timeout, $location, $document)->
  # Scroll to an element on page load
  restrict: "A"
  link: (scope, element, attr) ->
    elem = element
    $(window).load ->
      $timeout ->
        if elem?
          $document.scrollTo elem, 100, 200, (x) ->
            x * (2 - x)
