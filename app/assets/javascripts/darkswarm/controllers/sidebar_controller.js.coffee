window.SidebarCtrl = Darkswarm.controller "SidebarCtrl", ($scope, $location) ->
  $scope.active = ->
    $location.path() in ["/login", "/signup"]
