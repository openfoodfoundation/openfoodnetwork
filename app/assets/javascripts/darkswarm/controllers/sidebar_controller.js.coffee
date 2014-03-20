window.SidebarCtrl = Darkswarm.controller "SidebarCtrl", ($scope, $location) ->
  $scope.active_sidebar = $location.path()
  
  $scope.$watch ->
    $location.path()
  , ->
    $scope.active_sidebar = $location.path() 


  $scope.visible = ->
    $scope.active_sidebar != null and $scope.active_sidebar != ""
