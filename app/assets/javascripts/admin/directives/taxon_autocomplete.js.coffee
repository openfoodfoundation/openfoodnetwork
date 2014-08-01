angular.module("ofn.admin").directive "ofnTaxonAutocomplete", (Taxons) ->
  # Adapted from Spree's existing taxon autocompletion
  require: "ngModel"
  link: (scope,element,attrs,ngModel) ->
    setTimeout ->
      element.select2
        placeholder: Spree.translations.taxon_placeholder
        multiple: true
        initSelection: (element, callback) ->
          callback Taxons.findByIDs(element.val())
        query: (query) ->
          query.callback { results: Taxons.findByTerm(query.term) }
        formatResult: (taxon) ->
          taxon.name
        formatSelection: (taxon) ->
          taxon.name
    element.on "change", ->
      scope.$apply ->
        ngModel.$setViewValue element.val()