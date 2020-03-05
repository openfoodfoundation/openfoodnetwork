Darkswarm.controller "PagesetCtrl", ($scope, $location) ->
  $scope.selected = ->
    path = $location.path()?.match(/^\/\w+$/)?[0]
    if path
      path[1..]
    else
      $scope.defaultPage

  $scope.selectDefault = (selection) ->
    $scope.defaultPage = selection
