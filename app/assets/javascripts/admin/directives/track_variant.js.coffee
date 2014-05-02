Admin.directive "ofnTrackVariant", ['$parse', ($parse) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      dirtyVariants = {}
      dirtyVariants = scope.dirtyProducts[scope.product.id].variants  if scope.dirtyProducts.hasOwnProperty(scope.product.id) and scope.dirtyProducts[scope.product.id].hasOwnProperty("variants")
      if ngModel.$dirty
        parsedPropertyName = $parse(attrs.ofnTrackVariant)
        addDirtyProperty dirtyVariants, scope.variant.id, parsedPropertyName, viewValue
        addDirtyProperty scope.dirtyProducts, scope.product.id, $parse("variants"), dirtyVariants
        scope.displayDirtyProducts()
      viewValue
  ]