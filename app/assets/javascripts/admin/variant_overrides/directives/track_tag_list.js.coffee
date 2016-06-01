angular.module("admin.variantOverrides").directive "trackTagList", (VariantOverrides, DirtyVariantOverrides) ->
  link: (scope, element, attrs) ->
    watchString = "variantOverrides[#{scope.hub_id}][#{scope.variant.id}].tag_list"
    scope.$watch watchString, (newValue, oldValue) ->
      if typeof newValue isnt 'undefined' && newValue != oldValue
        scope.inherit = false
        vo_id = scope.variantOverrides[scope.hub_id][scope.variant.id].id
        DirtyVariantOverrides.set scope.hub_id, scope.variant.id, vo_id, 'tag_list', newValue
        scope.displayDirty()
