angular.module("admin.indexUtils").directive "panelToggle", ->
  restrict: "C"
  transclude: true
  template: '<div ng-transclude></div><i class=\'icon-chevron-down\'"></i>'
  require: "^panelToggleRow"
  scope:
    name: "@"
  link: (scope, element, attrs, ctrl) ->
    scope.selected = ctrl.register(scope.name, element)

    element.on "click", ->
      scope.selected = ctrl.select(scope.name)
