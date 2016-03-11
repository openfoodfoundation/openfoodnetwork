angular.module("admin.indexUtils").directive "toggleView", (Views) ->
  link: (scope, element, attrs) ->
    Views.register
    element.addClass "selected" if scope.view.visible

    element.click "click", ->
      scope.$apply ->
        Views.selectView(scope.viewKey)

    scope.$watch "view.visible", (newValue, oldValue) ->
      element.toggleClass "selected", scope.view.visible
