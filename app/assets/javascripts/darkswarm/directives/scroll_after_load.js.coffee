Darkswarm.directive 'scrollAfterLoad', ($timeout, $location, $document)->
  restrict: "A"
  link: (scope, element, attr) ->
    if scope.$last is true
      $(window).load ->
        $timeout ->
          $document.scrollTo $("##{$location.hash()}"), 100, 200, (x)->
            x * (2 - x)
