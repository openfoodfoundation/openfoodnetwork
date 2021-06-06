angular.module("admin.taxons").directive "ofnTaxonAutocomplete", (Taxons, AutocompleteSelect2) ->
  # Adapted from Spree's existing taxon autocompletion
  scope: true
  link: (scope,element,attrs) ->
    multiple = scope.$eval attrs.multipleSelection
    placeholder = attrs.placeholder
    initialSelection = scope.$eval attrs.ngModel

    setTimeout ->
      AutocompleteSelect2.autocomplete(
        multiple,
        placeholder,
        element,
        (-> Taxons.findByID(initialSelection)),
        (-> Taxons.findByIDs(initialSelection)),
        ((term) -> Taxons.findByTerm(term))
      )
