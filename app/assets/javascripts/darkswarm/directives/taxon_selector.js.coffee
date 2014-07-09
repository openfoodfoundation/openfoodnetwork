Darkswarm.directive "taxonSelector", (TaxonSelector) ->
  restrict: 'E'
  templateUrl: "taxon_selector.html"
  link: (scope, elem, attr)->
    scope.TaxonSelector = TaxonSelector
