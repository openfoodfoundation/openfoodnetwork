Darkswarm.directive "offcanvas",  ->
  restrict: "A"

  link: (scope, el, attr) ->
    el.find(".left-off-canvas-toggle").bind 'click', ->
      el.toggleClass 'move-right'
