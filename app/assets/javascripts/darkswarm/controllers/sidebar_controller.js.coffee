Darkswarm.controller "SidebarCtrl", ($scope, $location) ->
  $scope.sidebarPaths = ["/login", "/signup", "/forgot", "/account"] 

  $scope.active = ->
    $location.path() in $scope.sidebarPaths 
