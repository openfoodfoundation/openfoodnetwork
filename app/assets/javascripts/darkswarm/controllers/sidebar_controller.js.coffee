window.SidebarCtrl = Darkswarm.controller "SidebarCtrl", ($scope, $location) ->
  $scope.$watch ->
    $location.path()
  , ->
    $scope.active_sidebar = $location.path() 


  $scope.active = ->
    return "active" if $scope.active_sidbar != null and $scope.active_sidebar != ""
