Darkswarm.controller "HubNodeCtrl", ($scope, Navigation, $location, $anchorScroll, $templateCache, CurrentHub) ->
  $scope.toggle = ->
    Navigation.navigate $scope.hub.path

  $scope.open = ->
    $location.path() == $scope.hub.path
  
  $scope.current = ->
    $scope.hub.id is CurrentHub.id

  $scope.emptiesCart = ->
    CurrentHub.id isnt undefined and !$scope.current() 

  $scope.changeHub = ->
    if confirm "Are you sure? This will change your selected Hub and remove any items in you shopping cart."
      Navigation.go $scope.hub.path 

  if $scope.open()
    $anchorScroll()

