Darkswarm.controller "HubNodeCtrl", ($scope, HashNavigation, Navigation, $location, $templateCache, CurrentHub) ->
  $scope.toggle = (e) ->
    HashNavigation.toggle $scope.hub.hash if !angular.element(e.target).inheritedData('is-link')

  $scope.open = ->
    HashNavigation.active $scope.hub.hash
  
  $scope.current = ->
    $scope.hub.id is CurrentHub.hub.id
