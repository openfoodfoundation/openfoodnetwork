Darkswarm.directive "taxonSelector",  (FilterSelectorsService)->
  restrict: 'E'
  scope:
    objects: "&"
    results: "="
  templateUrl: "taxon_selector.html"

  link: (scope, elem, attr)->
    selectors_by_id = {}
    selectors = ["foo"]

    scope.emit = ->
      scope.results = selectors.filter (selector)->
        selector.active
      .map (selector)->
        selector.taxon.id

    scope.selectors = ->
      taxons = {} 
      selectors = []
      for object in scope.objects()
        for taxon in (object.taxons.concat object?.supplied_taxons)
          taxons[taxon.id] = taxon
      for id, taxon of taxons
        if selector = selectors_by_id[id]
          selectors.push selector
        else
          selector = selectors_by_id[id] = FilterSelectorsService.new
            taxon: taxon
          selectors.push selector
      selectors
