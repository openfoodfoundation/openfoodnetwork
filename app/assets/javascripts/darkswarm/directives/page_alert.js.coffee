angular.module('Darkswarm').directive "ofnPageAlert", ($timeout) ->
  restrict: 'A'
  scope: true
  link: (scope, elem, attrs) ->
    moveSelectors = [".off-canvas-wrap .inner-wrap",
                     ".off-canvas-wrap .inner-wrap .fixed",
                     ".off-canvas-fixed .top-bar",
                     ".off-canvas-fixed ofn-flash",
                     ".off-canvas-fixed nav.tab-bar",
                     ".off-canvas-fixed .page-alert"]

    container_elems = $(moveSelectors.join(", "))

    # Wait a moment after page load before showing the alert. Otherwise we often miss the
    # start of the animation.
    $timeout ->
      container_elems.addClass("move-up")
    , 1000

    scope.close = ->
      container_elems.removeClass("move-up")
