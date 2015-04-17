Darkswarm.controller "GroupEnterpriseNodeCtrl", ($scope, CurrentHub) ->

  $scope.active = false

  $scope.toggle = ->
    $scope.active = !$scope.active

  $scope.open = ->
    $scope.active

  $scope.current = ->
    $scope.hub.id is CurrentHub.hub.id
