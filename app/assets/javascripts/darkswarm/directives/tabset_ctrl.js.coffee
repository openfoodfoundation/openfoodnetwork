angular.module('Darkswarm').directive "tabsetCtrl", (Tabsets, $location, $rootScope) ->
  restrict: "C"
  scope:
    id: "@"
    selected: "@"
    navigate: "="
    prefix: "@?"
  controller: ($scope, $element) ->
    if $scope.navigate
      path = $location.path()?.match(/^\/\w+$/)?[0]
      $scope.selected = path[1..] if path
    
    # Watch location change success event to operate back/forward buttons
    $rootScope.$on "$locationChangeSuccess", ->
      if $scope.navigate
        path = $location.path()?.match(/^\/\w+$/)?[0]
        Tabsets.toggle($scope.id, path[1..] if path)
     
    this.toggle = (name) ->
      Tabsets.toggle($scope.id, name)

    this.select = (selection) ->
      $scope.$broadcast("selection:changed", selection)
      $element.toggleClass("expanded", selection?)
      $location.path(selection) if $scope.navigate

    this.registerSelectionListener = (callback) ->
      $scope.$on "selection:changed", (event, selection) ->
        callback($scope.prefix, selection)

    this

  link: (scope, element, attrs, ctrl) ->
    Tabsets.register(ctrl, scope.id, scope.selected)
