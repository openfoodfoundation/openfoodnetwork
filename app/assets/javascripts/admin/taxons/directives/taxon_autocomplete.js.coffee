angular.module("admin.taxons").directive "ofnTaxonAutocomplete", (Taxons) ->
  # Adapted from Spree's existing taxon autocompletion
  scope: true
  link: (scope,element,attrs) ->
    multiple = scope.$eval attrs.multipleSelection
    placeholder = attrs.placeholder
    initalSelection = scope.$eval attrs.ngModel

    setTimeout ->
      element.select2
        placeholder: placeholder
        multiple: multiple
        initSelection: (element, callback) ->
          if multiple
            callback Taxons.findByIDs(initalSelection)
          else
            callback Taxons.findByID(initalSelection)
        query: (query) ->
          query.callback { results: Taxons.findByTerm(query.term) }
        formatResult: (taxon) ->
          taxon.name
        formatSelection: (taxon) ->
          taxon.name