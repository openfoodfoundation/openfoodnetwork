Darkswarm.directive "pagesetCtrl", (Tabsets, $location) ->
  restrict: "C"
  scope:
    id: "@"
    selected: "@"
    prefix: "@?"
  controller: ($scope, $element) ->
    path = $location.path()?.match(/^\/\w+$/)?[0]
    $scope.selected = path[1..] if path

    this.toggle = (name) ->
      Tabsets.toggle($scope.id, name, "open")

    this.select = (selection) ->
      $scope.$broadcast("selection:changed", selection)
      $element.toggleClass("expanded", selection?)
      $location.path(selection)

    this.registerSelectionListener = (callback) ->
      $scope.$on "selection:changed", (event, selection) ->
        callback($scope.prefix, selection)

    this

  link: (scope, element, attrs, ctrl) ->
    Tabsets.register(ctrl, scope.id, scope.selected)
