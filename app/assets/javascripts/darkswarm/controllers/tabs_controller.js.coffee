Darkswarm.controller "TabsCtrl", ($scope, $rootScope, $location, OrderCycle) ->
  # Return active if supplied path matches url hash path.
  $scope.active = (path)->
    $location.hash() == path

  # Toggle tab selected status by setting the url hash path.
  $scope.select = (path)->
    if $scope.active(path)
      $location.hash ""
    else
      $location.hash path
