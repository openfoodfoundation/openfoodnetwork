Darkswarm.controller "HubNodeCtrl", ($scope, HashNavigation, Navigation, $location, $templateCache, CurrentHub) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.hub.hash

  $scope.open = ->
    HashNavigation.active $scope.hub.hash
  
  $scope.current = ->
    $scope.hub.id is CurrentHub.id
