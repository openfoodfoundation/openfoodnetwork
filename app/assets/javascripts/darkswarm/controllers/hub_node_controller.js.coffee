Darkswarm.controller "HubNodeCtrl", ($scope, Navigation, $location, $anchorScroll) ->
  $scope.toggle = ->
    Navigation.navigate $scope.hub.path

  $scope.active = ->
    $location.path() == $scope.hub.path

  if $scope.active()
    console.log "scrolling baby"
    $anchorScroll()

