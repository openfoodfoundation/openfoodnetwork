Admin.directive "ofnTrackProduct", ['$parse', ($parse) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty
        parsedPropertyName = $parse(attrs.ofnTrackProduct)
        addDirtyProperty scope.dirtyProducts, scope.product.id, parsedPropertyName, viewValue
        scope.displayDirtyProducts()
      viewValue
  ]