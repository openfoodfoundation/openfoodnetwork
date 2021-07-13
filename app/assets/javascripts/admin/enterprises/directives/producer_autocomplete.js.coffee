angular.module("admin.enterprises").directive "ofnProducerAutocomplete", (Enterprises, AutocompleteSelect2) ->
  scope: true
  link: (scope,element,attrs) ->
    scope.loadSuppliers() if !scope.suppliers
    multiple = scope.$eval attrs.multipleSelection
    placeholder = attrs.placeholder
    initialSelection = scope.$eval attrs.ngModel

    setTimeout ->
      scope.suppliers.$promise.then (data) ->
        AutocompleteSelect2.autocomplete(
          multiple,
          placeholder,
          element,
          (-> Enterprises.findByID(initialSelection)),
          (-> Enterprises.findByIDs(initialSelection)),
          ((term) -> Enterprises.findByTerm(scope.suppliers, term))
        )
