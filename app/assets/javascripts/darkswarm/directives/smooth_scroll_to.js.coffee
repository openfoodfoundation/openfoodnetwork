Darkswarm.directive "ofnSmoothScrollTo", ($location, $document)->
  # Onclick sets $location.hash to attrs.ofnScrollTo
  # Then triggers $document.scrollTo
  restrict: 'A'
  link: (scope, element, attrs)->
    element.bind 'click', (ev)->
      ev.stopPropagation()
      $location.hash attrs.ofnScrollTo
      target = $("a[name='#{attrs.ofnSmoothScrollTo}']")
      # Scrolling is confused by our position:fixed top bar and page alert bar
      # - add an offset to scroll to the correct location, plus 5px buffer
      offset  = $("nav.top-bar").height()
      offset += $(".page-alert.move-down").height()
      offset += 5
      $document.scrollTo target, offset, 1000
