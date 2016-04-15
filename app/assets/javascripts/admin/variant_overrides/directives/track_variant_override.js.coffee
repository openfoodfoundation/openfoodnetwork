angular.module("admin.variantOverrides").directive "ofnTrackVariantOverride", (DirtyVariantOverrides) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty
        scope.inherit = false
        vo_id = scope.variantOverrides[scope.hub_id][scope.variant.id].id
        DirtyVariantOverrides.set scope.hub_id, scope.variant.id, vo_id, attrs.ofnTrackVariantOverride, viewValue
        scope.displayDirty()
      viewValue
