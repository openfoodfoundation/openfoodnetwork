angular.module("admin.indexUtils").directive "panelToggle", (Panels) ->
  restrict: "E"
  replace: true
  transclude: true
  template: "<div ng-transclude></div>"
  scope:
    name: "@name"
    object: "&object"
  link: (scope, element, attrs) ->
    element.on "click", ->
      Panels.toggle(scope.object().id, scope.name)
