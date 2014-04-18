Darkswarm.controller "HubsCtrl", ($scope, Hubs) ->
  console.log Hubs.hubs[0]
  $scope.Hubs = Hubs
  $scope.hubs = Hubs.hubs
