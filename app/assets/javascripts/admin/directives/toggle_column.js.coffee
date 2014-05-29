angular.module("ofn.admin").directive "ofnToggleColumn", ->
  link: (scope, element, attrs) ->
    element.addClass "selected" if scope.column.visible
    element.click "click", ->
      scope.$apply ->
        if scope.column.visible
          scope.column.visible = false
          element.removeClass "selected"
        else
          scope.column.visible = true
          element.addClass "selected"