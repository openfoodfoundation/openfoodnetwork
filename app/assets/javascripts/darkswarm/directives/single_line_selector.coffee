Darkswarm.directive 'singleLineSelector', ($timeout, $filter) ->
  restrict: 'E'
  link: (scope,element,attrs) ->
    scope.fitting = false

    scope.overFlowSelectors = ->
      return [] unless scope.taxonSelectors?
      $filter('filter')(scope.taxonSelectors, { fits: false })

    scope.selectedOverFlowSelectors = ->
      $filter('filter')(scope.overFlowSelectors(), { active: true })

    # had to duplicate this to make overflow selectors work
    scope.emit = ->
      scope.activeTaxons = scope.taxonSelectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.taxon.id

    # From: http://stackoverflow.com/questions/4298612/jquery-how-to-call-resize-event-only-once-its-finished-resizing
    debouncer = (func, timeout) ->
      timeoutID = undefined
      timeout = timeout or 50
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
      scope.fitting = false

    scope.$watchCollection "taxonSelectors", ->
      if scope.taxonSelectors?
        scope.fitting = true
        selector.fits = true for selector in scope.taxonSelectors
        $timeout fit, 0, true

    $(window).resize debouncer (e) ->
      scope.fitting = true
      scope.$apply -> selector.fits = true for selector in scope.taxonSelectors
      $timeout fit, 0, true
