angular.module("ofn.admin").directive "ofnTrackVariant", ["DirtyProducts", (DirtyProducts) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty
        DirtyProducts.addVariantProperty scope.product.id, scope.variant.id, attrs.ofnTrackVariant, viewValue
        scope.displayDirtyProducts()
      viewValue
  ]