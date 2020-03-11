Darkswarm.controller "PageSelectionCtrl", ($scope, $location) ->
  $scope.selected = ->
    $location.path()[1..] || $scope.defaultPage

  $scope.selectDefault = (selection) ->
    $scope.defaultPage = selection
