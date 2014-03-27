Darkswarm.controller "TabsCtrl", ($scope, $rootScope, $location, OrderCycle) ->
  $scope.active = (path)->
    if !OrderCycle.selected() and $location.hash() == "" and path == "/about"
      true
    else
      $location.hash() == path


  $scope.tabs = ["contact", "about", "groups", "producers"]
  for tab in $scope.tabs 
    $scope[tab] =
      path: "/" + tab 

  $scope.select = (tab)->
    if $scope.active(tab.path)
      $location.hash "/"
    else
      $location.hash tab.path
