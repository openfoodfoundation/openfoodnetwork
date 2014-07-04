Darkswarm.directive "taxonSelector", (TaxonSelector) ->
  restrict: 'E'
  scope:
    enterprises: "="
  templateUrl: "taxon_selector.html"
  link: (scope, elem, attr)->
    scope.TaxonSelector = TaxonSelector
    TaxonSelector.collectTaxons scope.enterprises
