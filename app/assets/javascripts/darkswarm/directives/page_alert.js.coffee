Darkswarm.directive "ofnPageAlert", ($timeout) ->
  restrict: 'A'
  scope: true
  link: (scope, elem, attrs) ->
    container_elems = $(".off-canvas-wrap .inner-wrap, .off-canvas-wrap .inner-wrap .fixed, .page-alert")

    # Wait a moment after page load before showing the alert. Otherwise we often miss the
    # start of the animation.
    $timeout ->
      container_elems.addClass("move-down")
    , 1000

    scope.close = ->
      container_elems.removeClass("move-down")
