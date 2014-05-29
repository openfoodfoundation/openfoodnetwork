angular.module("ofn.admin").directive "ofnTrackProduct", ["DirtyProducts", (DirtyProducts) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty
        DirtyProducts.addProductProperty scope.product.id, attrs.ofnTrackProduct, viewValue
        scope.displayDirtyProducts()
      viewValue
  ]