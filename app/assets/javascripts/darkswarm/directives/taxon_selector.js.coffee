Darkswarm.directive "taxonSelector",  (FilterSelectorsService)->
  # Automatically builds activeSelectors for taxons
  # Lots of magic here
  restrict: 'E'
  replace: true
  scope:
    objects: "&"
    results: "="
  templateUrl: "taxon_selector.html"

  link: (scope, elem, attr)->
    selectors_by_id = {}
    selectors = null  # To get scoping/closure right

    scope.emit = ->
      scope.results = selectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.taxon.id

    # Build hash of unique taxons, each of which gets an ActiveSelector
    scope.selectors = ->
      taxons = {} 
      selectors = []
      for object in scope.objects()
        for taxon in object.taxons
          taxons[taxon.id] = taxon
        if object.supplied_taxons
          for taxon in object.supplied_taxons
            taxons[taxon.id] = taxon
      
      # Generate a selector for each taxon.
      # NOTE: THESE ARE MEMOIZED to stop new selectors from being created constantly, otherwise function always returns non-identical results
      # This means the $digest cycle can never close and times out
      # See http://stackoverflow.com/questions/19306452/how-to-fix-10-digest-iterations-reached-aborting-error-in-angular-1-2-fil
      for id, taxon of taxons
        if selector = selectors_by_id[id]
          selectors.push selector
        else
          selector = selectors_by_id[id] = FilterSelectorsService.new
            taxon: taxon
          selectors.push selector
      selectors
