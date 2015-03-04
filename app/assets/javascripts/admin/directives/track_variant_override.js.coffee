angular.module("ofn.admin").directive "ofnTrackVariantOverride", (DirtyVariantOverrides) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty
        variantOverride = scope.variantOverrides[scope.hub.id][scope.variant.id]
        DirtyVariantOverrides.add variantOverride
        scope.displayDirty()
      viewValue
