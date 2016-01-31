angular.module("admin.variantOverrides").directive "trackInheritance", (VariantOverrides, DirtyVariantOverrides) ->
  require: "ngModel"
  link: (scope, element, attrs, ngModel) ->
    # This is a bit hacky, but it allows us to load the inherit property on the VO, but then not submit it
    scope.inherit = angular.equals scope.variantOverrides[scope.hub.id][scope.variant.id], VariantOverrides.newFor scope.hub.id, scope.variant.id

    ngModel.$parsers.push (viewValue) ->
      if ngModel.$dirty && viewValue
        variantOverride = VariantOverrides.inherit(scope.hub.id, scope.variant.id)
        DirtyVariantOverrides.add variantOverride
        scope.displayDirty()
      viewValue
