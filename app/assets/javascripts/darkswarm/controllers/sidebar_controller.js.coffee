window.SidebarCtrl = Darkswarm.controller "SidebarCtrl", ($scope, $location) ->
  $scope.active = ->
    $location.path() == "/login" || $location.path() == "/signup"
