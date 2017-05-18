Darkswarm.directive "tab", ->
  restrict: "C"
  require: "^^tabsetCtrl"
  scope:
    name: "@"
  link: (scope, element, attrs, ctrl) ->
    element.on "click", ->
      scope.$apply ->
        ctrl.toggle(scope.name)

    ctrl.registerSelectionListener (selection) ->
      element.toggleClass('selected', selection == scope.name)
