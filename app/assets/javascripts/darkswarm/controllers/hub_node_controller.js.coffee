Darkswarm.controller "HubNodeCtrl", ($scope, HashNavigation, $location, $anchorScroll, $templateCache, CurrentHub) ->
  $scope.toggle = ->
    HashNavigation.toggle $scope.hub.hash

  $scope.open = ->
    HashNavigation.active $scope.hub.hash
  
  $scope.current = ->
    $scope.hub.id is CurrentHub.id

  $scope.emptiesCart = ->
    CurrentHub.id isnt undefined and !$scope.current() 

  $scope.changeHub = ->
    if confirm "Are you sure? This will change your selected Hub and remove any items in you shopping cart."
      Navigation.go $scope.hub.path 
