Darkswarm.directive "taxonSelector", (TaxonSelector) ->
  restrict: 'E'
  scope: {}
  templateUrl: "taxon_selector.html"
  link: (scope, elem, attr)->
    scope.TaxonSelector = TaxonSelector
