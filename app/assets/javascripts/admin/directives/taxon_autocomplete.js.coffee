angular.module("ofn.admin").directive "ofnTaxonAutocomplete", (Taxons) ->
  # Adapted from Spree's existing taxon autocompletion
  scope: true
  link: (scope,element,attrs) ->
    multiple = scope.$eval attrs.multipleSelection
    placeholder = attrs.placeholder

    setTimeout ->
      element.select2
        placeholder: placeholder
        multiple: multiple
        initSelection: (element, callback) ->
          if multiple
            callback Taxons.findByIDs(scope.product.category_id)
          else
            callback Taxons.findByID(scope.product.category_id)
        query: (query) ->
          query.callback { results: Taxons.findByTerm(query.term) }
        formatResult: (taxon) ->
          taxon.name
        formatSelection: (taxon) ->
          taxon.name