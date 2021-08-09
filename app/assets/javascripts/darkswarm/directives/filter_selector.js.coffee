angular.module('Darkswarm').directive "filterSelector", ->
  # Automatically builds activeSelectors for taxons
  # Lots of magic here
  restrict: 'E'
  replace: true
  scope:
    selectorSet: '='
    objects: "&"
    activeSelectors: "=?"
    allSelectors: "=?" # Optional
  templateUrl: "filter_selector.html"

  link: (scope, elem, attr)->
    selectors_by_id = {}
    selectors = null  # To get scoping/closure right

    scope.readOnly = ->
      !attr.activeSelectors?

    scope.emit = ->
      scope.activeSelectors = selectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.object.id

    scope.$watchCollection "objects()", (newValue, oldValue) ->
      scope.allSelectors = scope.buildSelectors()

    # Build a list of selectors
    scope.buildSelectors = ->
      # Generate a selector for each object.
      # NOTE: THESE ARE MEMOIZED to stop new selectors from being created constantly, otherwise function always returns non-identical results
      # This means the $digest cycle can never close and times out
      # See http://stackoverflow.com/questions/19306452/how-to-fix-10-digest-iterations-reached-aborting-error-in-angular-1-2-fil
      selectors = []
      for id, object of scope.objects()
        if selector = selectors_by_id[id]
          selectors.push selector
        else
          selector = selectors_by_id[id] = scope.selectorSet.new
            object: object
          selectors.push selector
      selectors

    scope.ifDefined = (value, if_undefined) ->
      if angular.isDefined(value)
        value
      else
        if_undefined
