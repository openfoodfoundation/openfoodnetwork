angular.module("admin.indexUtils").directive "ofnToggleColumn", (Columns) ->
  link: (scope, element, attrs) ->
    element.addClass "selected" if scope.column.visible

    element.click "click", ->
      scope.$apply ->
        Columns.toggleColumn(scope.column)
        element.toggleClass "selected"
