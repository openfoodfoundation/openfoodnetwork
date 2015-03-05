Darkswarm.directive "filterSelector",  (FilterSelectorsService)->
  # Automatically builds activeSelectors for taxons
  # Lots of magic here
  restrict: 'E'
  replace: true
  scope:
    objects: "&"
    activeSelectors: "="
    allSelectors: "="
  templateUrl: "filter_selector.html"

  link: (scope, elem, attr)->
    selectors_by_id = {}
    selectors = null  # To get scoping/closure right

    scope.emit = ->
      scope.activeSelectors = selectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.object.id

    # This can be called from a parent scope
    # when data has been loaded, in order to pass
    # selectors up
    scope.$on 'loadFilterSelectors', ->
      scope.allSelectors = scope.selectors()

    # Build a list of selectors
    scope.selectors = ->
      # Generate a selector for each object.
      # NOTE: THESE ARE MEMOIZED to stop new selectors from being created constantly, otherwise function always returns non-identical results
      # This means the $digest cycle can never close and times out
      # See http://stackoverflow.com/questions/19306452/how-to-fix-10-digest-iterations-reached-aborting-error-in-angular-1-2-fil
      selectors = []
      for id, object of scope.objects()
        if selector = selectors_by_id[id]
          selectors.push selector
        else
          selector = selectors_by_id[id] = FilterSelectorsService.new
            object: object
          selectors.push selector
      selectors

    scope.ifDefined = (value, if_undefined) ->
      if angular.isDefined(value)
        value
      else
        if_undefined
