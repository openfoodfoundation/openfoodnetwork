Darkswarm.directive 'singleLineSelector', ($timeout) ->
  restrict: 'E'
  link: (scope,element,attrs) ->
    scope.activeTaxons = []
    scope.taxonSelectors = []

    # From: http://stackoverflow.com/questions/4298612/jquery-how-to-call-resize-event-only-once-its-finished-resizing
    debouncer = (func, timeout) ->
      timeoutID = undefined
      timeout = timeout or 200
      ->
        subject = this
        args = arguments
        clearTimeout timeoutID
        timeoutID = setTimeout(->
          func.apply subject, Array::slice.call(args)
        , timeout)

    fit = ->
      used = $(element).find("li.more").outerWidth(true)
      available = $(element).parent(".filter-box").innerWidth()
      $(element).find("li").not(".more").each (i) ->
        used += $(this).outerWidth(true)
        scope.taxonSelectors[i].fits = used <= available
        return null # So we don't exit the loop on false

    scope.$watchCollection "taxonSelectors", ->
      selector.fits = true for selector in scope.taxonSelectors
      $timeout fit, 0, true

    $(window).resize debouncer (e) ->
      scope.$apply -> selector.fits = true for selector in scope.taxonSelectors
      $timeout fit, 0, true
