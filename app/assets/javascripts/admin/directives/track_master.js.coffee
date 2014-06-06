angular.module("ofn.admin").directive "ofnTrackMaster", ["DirtyProducts", (DirtyProducts) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty
        DirtyProducts.addMasterProperty scope.product.id, scope.product.master.id, attrs.ofnTrackMaster, viewValue
        scope.displayDirtyProducts()
      viewValue
  ]