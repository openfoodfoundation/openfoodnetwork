angular.module("ofn.admin").directive "ofnTaxonAutocomplete", (Taxons) ->
  # Adapted from Spree's existing taxon autocompletion
  require: "ngModel"
  link: (scope,element,attrs,ngModel) ->
    setTimeout ->
      element.select2
        placeholder: Spree.translations.taxon_placeholder
        multiple: true
        initSelection: (element, callback) ->
          Taxons.findByIDs(element.val()).$promise.then (result) ->
            callback Taxons.cleanTaxons(result)
        query: (query) ->
          Taxons.findByTerm(query.term).$promise.then (result) ->
            query.callback { results: Taxons.cleanTaxons(result) }
        formatResult: (taxon) ->
          taxon.pretty_name
        formatSelection: (taxon) ->
          taxon.pretty_name
    element.on "change", ->
      scope.$apply ->
        ngModel.$setViewValue element.val()