Darkswarm.controller "HubNodeCtrl", ($scope, Navigation, $location, $anchorScroll) ->
  $scope.toggle = ->
    Navigation.navigate $scope.hub.path

  $scope.open = ->
    $location.path() == $scope.hub.path

  if $scope.open()
    $anchorScroll()

