angular.module("admin.indexUtils").directive "panelCtrl", (Panels) ->
  restrict: "C"
  scope:
    object: "="
    selected: "@?"
  controller: ($scope, $element) ->
    this.toggle = (name) ->
      Panels.toggle($scope.object, name)

    this.select = (selection) ->
      $scope.$broadcast("selection:changed", selection)
      $element.toggleClass("expanded", selection?)

    this.registerSelectionListener = (callback) ->
      $scope.$on "selection:changed", (event, selection) ->
        callback(selection)

    this

  link: (scope, element, attrs, ctrl) ->
    Panels.register(ctrl, scope.object, scope.selected)
