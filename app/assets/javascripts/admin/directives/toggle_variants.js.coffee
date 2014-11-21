angular.module("ofn.admin").directive "ofnToggleVariants", (DisplayProperties) ->
  link: (scope, element, attrs) ->
    if DisplayProperties.showVariants scope.product.id
      element.removeClass "icon-chevron-right"
      element.addClass "icon-chevron-down"
    else
      element.removeClass "icon-chevron-down"
      element.addClass "icon-chevron-right"

    element.on "click", ->
      scope.$apply ->
        if DisplayProperties.showVariants scope.product.id
          DisplayProperties.setShowVariants scope.product.id, false
          element.removeClass "icon-chevron-down"
          element.addClass "icon-chevron-right"
        else
          DisplayProperties.setShowVariants scope.product.id, true
          element.removeClass "icon-chevron-right"
          element.addClass "icon-chevron-down"