angular.module('Darkswarm').directive "tab", ->
  restrict: "C"
  require: "^^tabsetCtrl"
  scope:
    name: "@"
  link: (scope, element, attrs, ctrl) ->
    element.on "click", ->
      scope.$apply ->
        ctrl.toggle(scope.name)

    scope.$on "$destroy", ->
      element.off("click")

    ctrl.registerSelectionListener (prefix, selection) ->
      element.toggleClass('selected', selection == scope.name)
