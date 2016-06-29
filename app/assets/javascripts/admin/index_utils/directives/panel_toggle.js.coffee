angular.module("admin.indexUtils").directive "panelToggle", ->
  restrict: "C"
  transclude: true
  template: '<div ng-transclude></div><i class=\'icon-chevron\'></i>'
  require: "^^panelCtrl"
  scope:
    name: "@"
  link: (scope, element, attrs, ctrl) ->
    element.on "click", ->
      scope.$apply ->
        ctrl.toggle(scope.name)

    ctrl.registerSelectionListener (selection) ->
      element.toggleClass('selected', selection == scope.name)
