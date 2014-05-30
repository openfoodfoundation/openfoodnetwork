angular.module("ofn.admin").directive "ofnToggleVariants", ->
  link: (scope, element, attrs) ->
    if scope.displayProperties[scope.product.id].showVariants
      element.removeClass "icon-chevron-right"
      element.addClass "icon-chevron-down"
    else
      element.removeClass "icon-chevron-down"
      element.addClass "icon-chevron-right"
    element.on "click", ->
      scope.$apply ->
        if scope.displayProperties[scope.product.id].showVariants
          scope.displayProperties[scope.product.id].showVariants = false
          element.removeClass "icon-chevron-down"
          element.addClass "icon-chevron-right"
        else
          scope.displayProperties[scope.product.id].showVariants = true
          element.removeClass "icon-chevron-right"
          element.addClass "icon-chevron-down"