Darkswarm.directive "page", ->
  restrict: "C"
  require: "^^pagesetCtrl"
  scope:
    name: "@"
  link: (scope, element, attrs, ctrl) ->
    element.on "click", ->
      scope.$apply ->
        ctrl.toggle(scope.name)

    ctrl.registerSelectionListener (prefix, selection) ->
      element.toggleClass('selected', selection == scope.name)
