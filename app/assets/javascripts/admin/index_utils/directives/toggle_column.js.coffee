angular.module("admin.indexUtils").directive "toggleColumn", (Columns) ->
  link: (scope, element, attrs) ->
    element.addClass "selected" if scope.column.visible

    element.click "click", ->
      scope.$apply ->
        Columns.toggleColumn(scope.column)
        element.toggleClass "selected"
